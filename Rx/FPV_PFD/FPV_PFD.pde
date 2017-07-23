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

String status = "";

boolean TxReady = false;
final String remoteBtAddr = "B827EB69ED8B"; //MitchPi0
final int remoteBtPort = 9;
StreamConnection con; 
String rawConfig;
JSONObject config;

Process telPro, vidPro;
BufferedReader telPipe, vidPipe;

GLVideo drone_cam;

final boolean enableVideo = true; //For testing purposes. 

void setup() {
  size(800, 480, P2D); //resolution of display
  //TODO make fullscreen

  telLayer  = createGraphics(WIDTH, HEIGHT);
  telLayer.smooth(8);
  helvetica = loadFont("Courier-96.vlw");

  //Setup the bluetooth client and get the config data from drone
  initBT();

  //Create the GLVideo object without a pipeline. We'll do this later
  drone_cam = new GLVideo(this, "udpsrc port=9305 ! h264parse ! decodebin", GLVideo.NO_SYNC & GLVideo.MUTE);
  drone_cam.play();

  println("Setup complete");
}

void draw() {
  boolean vidStarted = false;
  if (TxReady) {
    //update and read the drone_cam footage
    if (enableVideo) {
      if (drone_cam != null && drone_cam.available()) {
        vidStarted = true;
        drone_cam.read();
        image(drone_cam, 0, 0, width, height);
      } 
      //if there's nothing availible, draw a loading screen. 
      //There should be something, ideally
      else {
        image(drone_cam, 0, 0, width, height);
        if (vidStarted) {
          textSize(height * 0.03f);
          fill(255);
          textAlign(CENTER, CENTER);
          text("Waiting for video", width/2, height/5);
          fill(128);
          arc(width/2, height/2, width/4, width/4, 
            0, 
            2*PI, 
            CHORD);
          fill(255);
          float angle = map(frameCount % 60, 0, 59, 0, 2 * PI);
          arc(width/2, height/2, width/4, width/4, 
            angle, 
            angle + PI, 
            PIE);
        }
      }
    }
    //If we don't enable video, we're really just looking to see that telemetry is 
    //Rendering correctly.
    else {
      background(0);
    }

    //Read telemetry data from the fifo
    try {
      String samples = "";
      //If there are more than one lines of telemetry, we only want the most recent
      while (telPipe.ready()) {
        samples = telPipe.readLine();
      }
      if (!samples.isEmpty()) {
        tel.updateAll(samples);
      }
    } 
    catch(IOException ioe) {
      println("Error with reading from telemetry pipe.");
      ioe.printStackTrace();
      exit();
    }

    //draw the telemetry layer
    drawTelemetry();
    image(telLayer, 0, 0);
    drawPipper(700, 150, 150, tel.getPitch(), tel.getAOB());
  } else {
    //wait for BT connection
    background(0, 0, 0);
    textAlign(CENTER, CENTER);
    textSize(0.035f * HEIGHT);
    text(status, width / 2, height / 2);
  }
}

//Called on applet shutdown
void stop() {
  println("Shutting down");
  if (drone_cam != null) drone_cam.close();
  try {
    if (telPipe != null) telPipe.close();
    if (vidPipe != null) vidPipe.close();
    if (con != null) con.close();
  }
  catch(IOException ioe) {
    //doesn't really matter on shutdown
  }
  if (telPro != null) telPro.destroy();
  if (vidPro != null) vidPro.destroy();
}

void initBT() {
  try {
    String serverURL = "btspp://" + remoteBtAddr + ":" + remoteBtPort;
    println("Opening " + serverURL + " on bluetooth");
    status = "Starting BT Client. Waiting for Connection";
    while (con == null) {
      try {
        con = (StreamConnection) Connector.open(serverURL, Connector.READ_WRITE, false);
      }
      catch(IOException ioe) {
        delay(3000);
        print(".");
      }
      catch(RuntimeException rte) {
        delay(3000);
        print(",");
      }
    }
    println("\tComms open. Reading.");
    status = "Got connection. Reading from it";
    InputStream is = con.openInputStream();

    byte buffer[] = new byte[1024 * 1024];
    int bytes_read = is.read(buffer);
    rawConfig = new String(buffer, 0, bytes_read);

    //convert the string from raw to java-friendly
    rawConfig.replaceAll("'", "\\\\");
    rawConfig.replaceAll("\"", "\\\\\"");
    println("\tGot data");
  } 
  catch(Exception btexception) {
    println("Hit generic exception on bt exchange. Con = " + con);
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
  status = "Parsing data";
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
    exit();
    return;
  }

  //Finally, set up the listeners that will pipe data into a place we can read them
  //Will be done on the command line, initialized here so we can forward data from the config file
  JSONObject networkSettings = config.getJSONObject("network");
  if (networkSettings == null) println("ERROR: No network settings found");

  int FECPacketsPerBlock = networkSettings.getInt("FECPacketsPerBlock", -1);
  int FECBlockSize = networkSettings.getInt("FECBlockSize", -1);
  int packetsPerBlock = networkSettings.getInt("PacketsPerBlock", -1);
  int transmissionsPerBlock = networkSettings.getInt("TransmissionsPerBlock", -1);

  String telDataOrder = networkSettings.getString("telDataOrder", "");
  tel = new Telemetry(telDataOrder);
  println("\tConfig loaded");

  println("Starting listening subprocesses");
  status = "Configuring interface";
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

    status = "Opening telemetry listener";
    //Start the process that reads telemetry
    println("\tStarting telemetry listener");
    ProcessBuilder telemetry = new ProcessBuilder("bash", sketchPath() + "/data/tel.bash").inheritIO();
    Map<String, String> telEnv = telemetry.environment();
    telEnv.put("packetsPerBlock", ""+packetsPerBlock);
    telEnv.put("fecPacketsPerBlock", ""+FECPacketsPerBlock);
    telEnv.put("fecBlockSize", ""+FECBlockSize);
    this.telPro = telemetry.start();
    telPipe = createReader("/tmp/tel");

    //read the fist line, and toss it. It's there to keep the OS from blocking while
    //we open the reader
    while (!telPipe.ready()) {
      delay(100);
    }
    telPipe.readLine();

    if (enableVideo) {
      status = "Opening video listener";
      //Start the process that reads video data
      println("\tStarting video listener");
      ProcessBuilder video = new ProcessBuilder("bash", sketchPath() + "/data/vid.bash").inheritIO();
      Map<String, String> vidEnv = video.environment();
      vidEnv.put("packetsPerBlock", ""+packetsPerBlock);
      vidEnv.put("fecPacketsPerBlock", ""+FECPacketsPerBlock);
      vidEnv.put("fecBlockSize", ""+FECBlockSize);
      this.vidPro = video.start();
    }
  }
  catch(IOException ioe) {
    println("IO Error on starting telemetry");
    ioe.printStackTrace();
    exit();
    return;
  }

  //changing this value starts the main interface
  status = "All systems ready";
  println("Transmitter configured");
  TxReady = true;
}