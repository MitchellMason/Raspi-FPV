import java.lang.*;

public class Telemetry {
  private String time;
  private String heading;
  private String AOB;
  private String pitch;
  private String alt;
  private String oat;
  private String batt;
  
  private String telDataOrder;
  private String[] telSplit;
  
  Telemetry(String telDataOrder) {
    this.telDataOrder = telDataOrder;
    
    //Comes in the form "{item1},{item2}" so that it's easier for python to use.
    //We want something more like "item1, item2" to make it easier for java to split
    if(telDataOrder == null){
      System.err.println("telDataOrder not valid");
      return;
    }
    telDataOrder = telDataOrder.replace("{", "");
    telDataOrder = telDataOrder.replace("}", "");
    telSplit = telDataOrder.split(",");
    
    //init the data
    time = "";
    heading = "000";
    AOB = "0";
    pitch = "0";
    alt = "000";
    oat = "0";
    batt = "0";
  }
  
  void updateAll(String packet){
    String[] data = packet.split(",");
    if(data.length != telSplit.length){
      System.out.println("Ignoring bad packet: " + packet);
      return;
    }
    for(int i=0; i<telSplit.length; i++){
      if(telSplit[i].equals("heading")){
        this.setHeading((int)Float.parseFloat(data[i]));
      }
      else if(telSplit[i].equals("altitude")){
        this.setAltitude((int)Float.parseFloat(data[i]));
      }
      else if(telSplit[i].equals("aob")){
        //convert radians to degrees
        this.setAOB(Float.parseFloat(data[i]));
      }
      else if(telSplit[i].equals("pitch")){
        this.setPitch(Float.parseFloat(data[i]));
      }
      else if(telSplit[i].equals("speed")){
        //TODO
      }
      else if(telSplit[i].equals("oat")){
        this.setOAT(Float.parseFloat(data[i]));
      }
      else if(telSplit[i].equals("time")){
        this.setTime(data[i]);
      }
      else if(telSplit[i].equals("batt")){
        //TODO
      }
    }
  }
  
  //time
  void setTime(String t){
    this.time = t;
  }
  
  String getTime(){
    return this.time;
  }

  //Heading
  void setHeading(int h) {
    if(h >= 360) h -= 360;
    if(h < 0) heading = "ERROR";
    else heading = String.format("%03d", h);
  }

  

  int getParsedHeading() {
    return Integer.parseInt(heading);
  }

  String getHeading() {
    return heading;
  }

  //AOB
  void setAOB(float a) {
    if(a > 90) a -= 180;
    if(a < -90) a += 180;
    AOB = ""+a;
  }

  float getAOB() {
    return Float.parseFloat(AOB);
  }

  //Pitch
  void setPitch(float p) {
    pitch = ""+p;
  }

  float getPitch() {
    return Float.parseFloat(pitch);
  }

  //Altitude
  void setAltitude(int a) {
    alt = String.format("%03d", a);
  }

  int getParsedAltitude() {
    return Integer.parseInt(alt);
  }

  String getAltitude() {
    return alt;
  }

  //OAT
  void setOAT(float o) {
    oat = ""+o;
  }

  float getOAT() {
    return Float.parseFloat(oat);
  }

  //Batt
  void setBatt(float b) {
    this.batt = ""+b;
  }
  float getBatt() {
    return Float.parseFloat(batt);
  }
}