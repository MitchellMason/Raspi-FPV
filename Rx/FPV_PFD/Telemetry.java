import java.lang.*;

public class Telemetry {
  private String heading;
  private String AOB;
  private String pitch;
  private String alt;
  private String oat;
  private String batt;

  Telemetry() {
    heading = "000";
    AOB = "0";
    pitch = "0";
    alt = "000";
    oat = "0";
    batt = "0";
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