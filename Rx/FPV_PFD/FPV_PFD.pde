import gohai.glvideo.*; //<>//

import java.net.*;
import java.io.IOException;

import java.util.Vector;
import java.util.List;
import java.util.Map;
import java.util.Collections;
import java.util.Arrays;

import javax.bluetooth.*;

PGraphics telLayer;
PFont helvetica;
Telemetry tel;

final int WIDTH = 800;
final int HEIGHT = 480;

final float ALT_TAPE_OFFSET = WIDTH*0.025f;
final int ALT_TAPE_RANGE = 100;
final int ALT_TAPE_INCR = 10;
final int MAX_ALT = 400;

final int HEADING_TAPE_RANGE = 100;
final int HEADING_TAPE_TICKS = 5;

final boolean DEBUG = false;

final String remoteBtAddr = "B827EB69ED8B"; //MitchPi0
final int remoteBtPort = 9;
StreamConnection con; 
String rawConfig;
JSONObject config;

Process telPro, vidPro;
BufferedReader telPipe, vidPipe;

GLMovie drone_cam;

void setup() {
  size(800, 480, P2D); //resolution of display
  //TODO make fullscreen

  telLayer  = createGraphics(WIDTH, HEIGHT);
  telLayer.smooth(8);
  helvetica = loadFont("Courier-96.vlw");
  tel = new Telemetry();

  //Setup the bluetooth client and get the config data from drone
  try {
    String serverURL = "btspp://" + remoteBtAddr + ":" + remoteBtPort;
    println("Opening " + serverURL + " on bluetooth");
    while (con == null) {
      try {
        con = (StreamConnection) Connector.open(serverURL, Connector.READ_WRITE, false);
      }
      catch(IOException ioe) {
        delay(3000);
        print(".");
      }
    }
    println("\tComms open. Reading.");
    OutputStream os = con.openOutputStream();
    InputStream is = con.openInputStream();
    RemoteDevice pi0 = RemoteDevice.getRemoteDevice(con);

    byte buffer[] = new byte[1024 * 1024];
    int bytes_read = is.read(buffer);
    rawConfig = new String(buffer, 0, bytes_read);

    //convert the string from raw to java-friendly
    rawConfig.replaceAll("'", "\\\\");
    rawConfig.replaceAll("\"", "\\\\\"");
    println("\tGot data");
  } 
  catch(Exception btexception) {
    println("Hit generic exception on bt exchange");
    btexception.printStackTrace();
    try {
      if (con != null) { 
        println("Connection was alive, closing");
        con.close();
      }
    }
    catch (IOException ioe) {
      //This shouldn't occur, but required by compiler
      println("Couldn't close connection.");
      ioe.printStackTrace();
    }
    exit(); //exit() won't immediately close the application. setup() has to complete first
    return;
  } 

  //Parse the JSON data we received 
  try {
    this.config = parseJSONObject(rawConfig);
    if (config == null) {
      println("Can't parse JSON object.");
      throw new java.lang.RuntimeException("JSON parse error");
    }
  }
  catch(java.lang.RuntimeException e) {
    println("Error with parsing JSON. Data:\n" + rawConfig + "\n");
    e.printStackTrace();
  }

  //Finally, set up the listeners that will pipe data into a place we can read them
  //Will be done on the command line, initialized here so we can forward data from the config file
  JSONObject networkSettings = config.getJSONObject("network");
  if (networkSettings == null) println("ERROR: No network settings found");

  int bytesPerPacket = networkSettings.getInt("bytesPerPacket", -1);
  int fec = networkSettings.getInt("fec", -1);
  int packetsPerBlock = networkSettings.getInt("packetsPerBlock", -1);
  println("\tConfig loaded");

  //check for errors
  //TODO

  println("Starting listening subprocesses");
  try {
    println("\t Priming Antenna for FPV");
    ProcessBuilder primeAntenna = new ProcessBuilder("bash", sketchPath() + "/data/prime.bash").inheritIO();
    Process primePro = primeAntenna.start();

    //we need the process to complete before moving on, otherwise we risk trying to read from
    //an antenna that's not ready. 
    println("\t Waiting for it to complete");
    try {
      primePro.waitFor();
    } 
    catch(InterruptedException e) {
      println("Prime process interrrupted.");
      e.printStackTrace();
      exit();
      return;
    }

    //Start the process that reads telemetry
    println("\tStarting telemetry listener");
    ProcessBuilder telemetry = new ProcessBuilder("bash", sketchPath() + "/data/tel.bash").inheritIO();
    Map<String, String> telEnv = telemetry.environment();
    telEnv.put("packetsPerBlock", ""+packetsPerBlock);
    telEnv.put("fec", ""+fec);
    telEnv.put("bytesPerPacket", ""+bytesPerPacket);
    this.telPro = telemetry.start();
    telPipe = createReader("/tmp/tel");

    //Start the process that reads video data
    println("\tStarting video listener");
    ProcessBuilder video = new ProcessBuilder("bash", sketchPath() + "/data/vid.bash").inheritIO();
    Map<String, String> vidEnv = video.environment();
    vidEnv.put("packetsPerBlock", ""+packetsPerBlock);
    vidEnv.put("fec", ""+fec);
    vidEnv.put("bytesPerPacket", ""+bytesPerPacket);
    this.vidPro = video.start();
    drone_cam = new GLMovie(this, "/tmp/vid");
    drone_cam.enableDebug();
  }
  catch(IOException ioe) {
    println("IO Error on starting telemetry");
    ioe.printStackTrace();
    exit();
    return;
  }


  println("Setup complete");
}

void draw() {
  
  //update the tel data
  updateData();
  
  //update and read the drone_cam footage
  if(drone_cam.available()){
    background(0,255,0);
    drone_cam.read();
    drone_cam.play();
  }
  else{
    background(255,0,0);
  }
  
  image(drone_cam, 0,0,width, height);
  

  telLayer.beginDraw();
  drawTelemetry();
  telLayer.endDraw();

  image(telLayer, 0, 0);

  if (DEBUG) {
    tel.setHeading((int)map(mouseX, 0, width, 0, 720));
    tel.setAltitude((int)map(mouseY, 0, height, 500, 0));
    tel.setAOB(tel.getAOB() + 0.1f);
  }
}

void updateData() {
  try {
    if (telPipe != null && telPipe.ready()) { ///TODO, remove null check
      String line = telPipe.readLine();
      if (line != null) {
        String[] samples = line.split(",");
        if (samples.length == 6) {
          //TODO use teldataorder as sent over bluetooth
          tel.setHeading(parseInt(samples[0]));

          //pressure -> alt taken from https://en.wikipedia.org/wiki/Pressure_altitude
          float millibars = parseFloat(samples[1]) / 100.0f;
          tel.setAltitude((int)((1-Math.pow(millibars / 1013.25, 0.190284)) * 145366.45));
          tel.setOAT(parseFloat(samples[2]));
          tel.setAOB(-1 * parseFloat(samples[5]) * 100);
        } else {
          println("Potentially bad sample received: " + line);
        }
      } else {
        println("Error: null string read from telemetry");
      }
    }
  } 
  catch(IOException ioe) {
    println("tel Pipe threw exception.");
    ioe.printStackTrace();
    exit();
    return;
  }
}

void drawTelemetry() {
  telLayer.background(255, 255, 255, 0);

  //set tape text data
  telLayer.textFont(helvetica);

  //TODO get live data

  //draw scoreboard text data
  telLayer.fill(255);
  telLayer.textSize(HEIGHT * .025);
  telLayer.textAlign(LEFT, TOP);
  telLayer.text("OAT: " + nf(tel.getOAT(), 2, 1) + "ºC Batt: XX%", ALT_TAPE_OFFSET + telLayer.textWidth("O"), 0);

  //draw the horizon
  telLayer.stroke(255, 255, 255);
  telLayer.strokeWeight(1);
  float aob = tel.getAOB() * (float)(Math.PI / 180);
  telLayer.line(
    WIDTH / 2, 
    HEIGHT / 2, 
    (WIDTH / 2) + cos(aob) * WIDTH, 
    (HEIGHT / 2) - sin(aob) * WIDTH
    );
  telLayer.line(
    WIDTH / 2, 
    HEIGHT / 2, 
    (WIDTH / 2) + cos(aob + (float)Math.PI) * WIDTH, 
    (HEIGHT / 2) - sin(aob + (float)Math.PI) * WIDTH
    );

  //draw the backdrop for the tapes
  telLayer.noStroke();
  telLayer.fill(0, 0, 0, 128);
  telLayer.rect(0, 0, ALT_TAPE_OFFSET, HEIGHT); //Alt
  telLayer.rect(ALT_TAPE_OFFSET * 3.75, HEIGHT * 0.95f, WIDTH - (7.75*ALT_TAPE_OFFSET), HEIGHT); //Heading

  //heading on the bottom, centered
  telLayer.textSize(HEIGHT * .05);
  telLayer.fill(255, 255, 255);
  telLayer.textAlign(CENTER, BOTTOM);
  telLayer.text(tel.getHeading(), WIDTH / 2, HEIGHT * 0.95);

  //Altitude on the left, centered with chevron
  telLayer.textSize(HEIGHT * .05);
  telLayer.noFill();
  telLayer.stroke(128);
  telLayer.strokeWeight(3.0);
  telLayer.strokeJoin(MITER);
  telLayer.beginShape();
  telLayer.vertex(ALT_TAPE_OFFSET + telLayer.textWidth("O") -3, (HEIGHT/2) -HEIGHT * .015);
  telLayer.vertex(ALT_TAPE_OFFSET +3, HEIGHT / 2);
  telLayer.vertex(ALT_TAPE_OFFSET + telLayer.textWidth("O") -3, (HEIGHT/2) +HEIGHT * .015);
  telLayer.endShape();

  if (tel.getParsedAltitude() < MAX_ALT)
    telLayer.fill(255, 255, 255);
  else
    telLayer.fill(255, 0, 0);
  telLayer.textAlign(LEFT, CENTER);
  telLayer.text(tel.getAltitude(), ALT_TAPE_OFFSET+ telLayer.textWidth("O"), HEIGHT / 2);

  //draw the Altitude tape (+/- 100 from current altitude)
  telLayer.textSize(10);
  telLayer.textAlign(LEFT, CENTER);
  telLayer.strokeCap(SQUARE);
  telLayer.strokeWeight(2);
  int tapeMin = tel.getParsedAltitude() - ALT_TAPE_RANGE;
  int tapeMax = tel.getParsedAltitude() + ALT_TAPE_RANGE;
  for (int i=tapeMin; i < tapeMax; i++) {
    if (i % ALT_TAPE_INCR == 0) {
      boolean fiftyFootIncr = (i%(ALT_TAPE_INCR*5) == 0);
      float yCoord = map(i, tapeMin, tapeMax, HEIGHT, 0);
      if (i >= MAX_ALT) { 
        telLayer.stroke(255, 0, 0);
        telLayer.fill(255, 0, 0);
      } else {
        telLayer.stroke(255);
        telLayer.fill(255);
      }
      if (fiftyFootIncr) {
        float textWidth = telLayer.textWidth(""+i);
        telLayer.line(0, yCoord, ALT_TAPE_OFFSET - textWidth, yCoord);
        telLayer.text(i, ALT_TAPE_OFFSET-textWidth, yCoord);
      } else {
        telLayer.line(0, yCoord, 0.25 * ALT_TAPE_OFFSET, yCoord);
      }
    }
  }

  //draw the Heading tape (+/- range from current heading)
  tapeMin = tel.getParsedHeading() - HEADING_TAPE_RANGE;
  tapeMax = tel.getParsedHeading() + HEADING_TAPE_RANGE;
  telLayer.fill(255);
  telLayer.stroke(255);
  telLayer.strokeWeight(4);
  telLayer.textAlign(CENTER, CENTER);
  for (int i=tapeMin; i<tapeMax; i+= 1) {
    boolean thirtyFootIncr = (i%30 == 0);
    float xCoord = map(i, tapeMin, tapeMax, ALT_TAPE_OFFSET * 4, WIDTH - (4*ALT_TAPE_OFFSET));
    if (i % HEADING_TAPE_TICKS == 0)
      telLayer.line(xCoord, HEIGHT, xCoord, HEIGHT * .975f);
    if (thirtyFootIncr) {
      String headingName = "";
      int temp = i;
      if (temp < 0) temp = 360 + temp;
      if (temp > 360) temp = temp-360;
      if (temp == 0 || temp ==360) headingName = "N";
      else if (temp == 90) headingName = "E";
      else if (temp == 180) headingName = "S";
      else if (temp == 270) headingName = "W";
      else headingName = ""+temp;

      telLayer.text(headingName, xCoord, HEIGHT * .96f);
    }
  }
}