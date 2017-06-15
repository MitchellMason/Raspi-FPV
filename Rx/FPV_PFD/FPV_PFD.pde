import processing.net.*; //<>// //<>// //<>//
import processing.video.*;
import java.net.*;

import java.io.IOException;
import java.util.Vector;
import javax.bluetooth.*;

PGraphics video;
PGraphics telLayer;
PFont helvetica;
Telemetry tel;
Movie camera;

final int WIDTH = 800;
final int HEIGHT = 480;

final float ALT_TAPE_OFFSET = WIDTH*0.025f;
final int ALT_TAPE_RANGE = 100;
final int ALT_TAPE_INCR = 10;
final int MAX_ALT = 400;

final int HEADING_TAPE_RANGE = 100;
final int HEADING_TAPE_TICKS = 5;

final boolean DEBUG = true;

processing.net.Client sensorListener;
Socket videoSock;

final String remoteBtAddr = "B827EB69ED8B"; //MitchPi0
final int remoteBtPort = 9;
StreamConnection con; 
JSONObject config;

void setup() {
  size(800, 480); //resolution of display
  //TODO make fullscreen

  video     = createGraphics(WIDTH, HEIGHT);
  telLayer  = createGraphics(WIDTH, HEIGHT);
  telLayer.smooth(8);
  helvetica = loadFont("Courier-96.vlw");
  tel = new Telemetry();

  try {
    print("Opening bluetooth comms");
    String serverURL = "btspp://" + remoteBtAddr + ":" + remoteBtPort;
    while (con == null) {
      try {
        con = (StreamConnection) Connector.open(serverURL, Connector.READ_WRITE, false);
      }
      catch(IOException ioe) {
        delay(3000);
        print(".");
      }
    }
    println("\nComms open");
    OutputStream os = con.openOutputStream();
    InputStream is = con.openInputStream();
    RemoteDevice pi0 = RemoteDevice.getRemoteDevice(con);
    
    byte buffer[] = new byte[1024 * 1024];
    int bytes_read = is.read(buffer);
    String received = new String(buffer, 0, bytes_read);
    println("Read from pi0: \n" + received);
  }

  catch(Exception btexception) {
    println("Bluetooth exception");
    btexception.printStackTrace();
    try {
      if (con != null) { 
        println("closing con");
        con.close();
      }
    }
    catch (IOException ioe) {
      println("doh...");
    }
    exit();
    return;
  } 


  try {
    //all telemetry data is read on this port, sent over a pipe. The same will happen for video
    println("Opening sensor listener");
    sensorListener = new processing.net.Client(this, "127.0.0.1", 8085);
    println("Done. Opening video socket");
    videoSock = new Socket("127.0.0.1", 5906); //temp
    println("Done");
    H264StreamPlayer hsd = new H264StreamPlayer(videoSock.getInputStream());
  }
  catch(IOException e) {
    println("io exception");
    e.printStackTrace();
    exit();
    return;
  }
  config = parseJSONObject(received);
  if(config == null) println("Can't parse JSON object.");
  println("Setup complete");
}

void draw() {
  background(0);

  //updateData();

  video.beginDraw();
  updateVideo();
  video.endDraw();

  telLayer.beginDraw();
  drawTelemetry();
  telLayer.endDraw();

  image(video, 0, 0);
  image(telLayer, 0, 0);

  if (DEBUG) {
    tel.setHeading((int)map(mouseX, 0, width, 0, 720));
    tel.setAltitude((int)map(mouseY, 0, height, 500, 0));
    tel.setAOB(tel.getAOB() + 0.1f);
  }
}

void updateData() {
  if (sensorListener.available() > 0) {
    String rawData = sensorListener.readString();
    //too many samples are sent. Just get the most recent
    String[] samples = rawData.split(":");

    if (samples.length == 6) {
      tel.setHeading(parseInt(samples[0]));

      //pressure -> alt taken from https://en.wikipedia.org/wiki/Pressure_altitude
      float millibars = parseFloat(samples[1]) / 100.0f;
      tel.setAltitude((int)((1-Math.pow(millibars / 1013.25, 0.190284)) * 145366.45));

      tel.setOAT(parseFloat(samples[2]));

      //x,y,z
      tel.setAOB(-1 * parseFloat(samples[3]) * 100);
    }
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

void updateVideo() {
  video.background(0);
}