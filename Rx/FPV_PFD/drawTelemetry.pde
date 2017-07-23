final float ALT_TAPE_OFFSET = WIDTH*0.025f;
final int ALT_TAPE_RANGE = 100;
final int ALT_TAPE_INCR = 10;
final int MAX_ALT = 400;

final int HEADING_TAPE_RANGE = 100;
final int HEADING_TAPE_TICKS = 5;

final boolean enableHeading = false;
final boolean enableAlt = true;

void drawTelemetry() {
  telLayer.beginDraw();
  telLayer.background(255, 255, 255, 0);

  //set tape text data
  telLayer.textFont(helvetica);

  //draw the backdrop for the tapes
  telLayer.noStroke();
  telLayer.fill(0, 0, 0, 128);
  telLayer.rect(0, 0, ALT_TAPE_OFFSET, HEIGHT); //Alt
  if (enableAlt) telLayer.rect(ALT_TAPE_OFFSET, 0, WIDTH, HEIGHT * .038);
  if (enableHeading) telLayer.rect(ALT_TAPE_OFFSET * 3.75, HEIGHT * 0.95f, WIDTH - (7.75*ALT_TAPE_OFFSET), HEIGHT); //Heading

  //draw scoreboard text data
  telLayer.fill(255);
  telLayer.textSize(HEIGHT * .035);
  telLayer.textAlign(LEFT, TOP);
  telLayer.text(
    tel.getTime() + //current time from TX
    " OAT: " + nf(tel.getOAT(), 2, 1) + //OAT
    //"ºC Batt: XX%" + //Battery
    " RX fps: " + nf(frameRate, 2, 3), //Rx framerate
    ALT_TAPE_OFFSET, 0); //(X,Y position)


  if (enableAlt) {
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
  }


  if (enableHeading) {
    //heading text readout on the bottom, centered
    telLayer.textSize(HEIGHT * .05);
    telLayer.fill(255, 255, 255);
    telLayer.textAlign(CENTER, BOTTOM);
    telLayer.text(tel.getHeading(), WIDTH / 2, HEIGHT * 0.95);

    //draw the Heading tape (+/- range from current heading)
    int tapeMin = tel.getParsedHeading() - HEADING_TAPE_RANGE;
    int tapeMax = tel.getParsedHeading() + HEADING_TAPE_RANGE;
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
  telLayer.endDraw();
}