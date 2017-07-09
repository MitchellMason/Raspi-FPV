//draw the attitude indicator at a specified (x,y) position, with a thickness of radius
//and displaying the data pitch and aob, given in degrees 0,360
void drawPipper(float x, float y, float radius, float pitch, float aob) {
  stroke(255); 
  fill(255);
  textSize(radius * .05f);
  text("AOB: " + aob, x-30, y-(radius / 2) - 15);
  text("Pitch: " + pitch, x - (radius / 2) - textWidth("Pitch: " + pitch), y - 30);
  
  //draw the horizon
  float pitchLimit = 60;

  stroke(255);
  if (pitch > pitchLimit) {
    //All sky
    fill(0, 0, 255);
    arc(x, y, radius, radius, 0, 2*PI, CHORD);
  } else if (pitch < -pitchLimit) {
    //All ground
    fill(150, 75, 0);
    arc(x, y, radius, radius, 0, 2*PI, CHORD);
    
  } else { //pitch within limits
    //sky
    fill(0, 0, 255);
    arc(x, y, radius, radius, 0, 2*PI, CHORD);
    
    //ground
    fill(150, 75, 0);
    float pitchCorrection = map(pitch, -pitchLimit, pitchLimit, -PI, 0);
    arc(x, y, radius, radius, 
      radians(HALF_PI + aob) + HALF_PI+pitchCorrection, 
      radians(HALF_PI + aob) + HALF_PI-pitchCorrection, CHORD);
  }

  //draw the pitch demarkations
  //TODO
  //final int tinyMarks = 10;
  //for (int i=1; i<tinyMarks; i++) {
  //  //draw the pitch lines
  //  stroke(255);
  //  PVector l, r;
  //  if (i % 5 == 0) { //draw longer lines at 5 degree marks
  //    l = new PVector(
  //      x - radius, 
  //      y);
  //    r = new PVector(
  //      x + radius, 
  //      y + map(i, 1, tinyMarks, 0, radius / pitchLimit));
  //  } else {
  //    l = new PVector(
  //      0, 
  //      0);
  //    r = new PVector(
  //      0, 
  //      0);
  //  }
  //  line(l.x, l.y, r.x, r.y);
  //}
  for (int i=15; i<180; i+=5) {
    //draw the pitch lines
  }

  //draw the tick marks around the circle
  float[] ticks = new float[]{0, 30, 45, 60, 75, 80, 85};
  PVector onCircle = new PVector(), tickEnd = new PVector();
  float tickScaleFactor = 1.05f;
  for (int i=0; i<ticks.length; i++) {
    //draw each tick from a point on the circle outward
    stroke(255);
    onCircle.x = x + cos(radians(ticks[i]))*(radius/2);
    onCircle.y = y - sin(radians(ticks[i]))*(radius/2);
    tickEnd.x = x + tickScaleFactor*cos(radians(ticks[i]))*(radius/2);
    tickEnd.y = y - tickScaleFactor*sin(radians(ticks[i]))*(radius/2);
    line(onCircle.x, onCircle.y, tickEnd.x, tickEnd.y);

    //draw the reciprical angle
    //TODO simply reflect the points across the circle for speed
    ticks[i] = 180 - ticks[i];
    onCircle.x = x + cos(radians(ticks[i]))*(radius/2);
    onCircle.y = y - sin(radians(ticks[i]))*(radius/2);
    tickEnd.x = x + tickScaleFactor*cos(radians(ticks[i]))*(radius/2);
    tickEnd.y = y - tickScaleFactor*sin(radians(ticks[i]))*(radius/2);
    line(onCircle.x, onCircle.y, tickEnd.x, tickEnd.y);
  }

  //draw the zero degree tick mark
  float tickSize = radius/30;
  PShape zeroTick = createShape();
  zeroTick.beginShape();
  zeroTick.noFill();
  zeroTick.vertex(0, 0);
  zeroTick.vertex(tickSize, -tickSize);
  zeroTick.vertex(-tickSize, -tickSize);
  zeroTick.endShape(CLOSE);
  shape(zeroTick, x, y-radius/2);

  //draw the moving indicator tick mark
  PShape aobTick = createShape();
  PVector base = new PVector(0, radius/2), 
    l = new PVector(0-tickSize, (radius/2)-tickSize), 
    r = new PVector(0+tickSize, (radius/2)-tickSize), 
    pos = new PVector(x, y);

  float rad = radians(aob - 180);
  //if(rad < -HALF_PI){ rad += (rad - HALF_PI);}
  //if(rad >  HALF_PI){ rad -= (rad + HALF_PI);}
  base = rotateAroundPoint(base, new PVector(0, 0), rad);
  l = rotateAroundPoint(l, new PVector(0, 0), rad);
  r = rotateAroundPoint(r, new PVector(0, 0), rad);

  aobTick.beginShape();
  aobTick.fill(255);
  aobTick.vertex(base.x, base.y);
  aobTick.vertex(l.x, l.y);
  aobTick.vertex(r.x, r.y);
  aobTick.endShape(CLOSE);
  shape(aobTick, pos.x, pos.y);

  //draw the pipper
  PShape pipper = createShape();
  tickSize *= 2;
  pipper.beginShape();
  pipper.fill(255);
  pipper.stroke(0);
  pipper.vertex(0, 0);
  pipper.vertex(-tickSize, tickSize);
  pipper.vertex(0, tickSize/2);
  pipper.vertex(tickSize, tickSize);
  pipper.endShape(CLOSE);
  shape(pipper, x, y);
}


PVector rotateAroundPoint(PVector p, PVector origin, float angle) {
  float s = sin(angle);
  float c = cos(angle);

  p.x -= origin.x;
  p.y -= origin.y;

  float xnew = p.x * c - p.y * s;
  float ynew = p.x * s + p.y * c;

  p.x = xnew + origin.x;
  p.y = ynew + origin.y;

  return p;
}