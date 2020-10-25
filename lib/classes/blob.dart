import 'package:flutter/material.dart';

class Blob {
  double veloX;
  double veloY;
  double radius;
  Offset center;

  Blob(this.veloX, this.veloY, this.radius, this.center);

  update(Size size, double radiusScale) {
    int boundOffset = 50;
    double radiusBound = 50.0;
    //give opposite velocity when hits a vertical bound
    if (this.center.dx - radius < boundOffset ||
        this.center.dx > size.width - radius - boundOffset) {
      this.veloX *= -1;
    }
    //give opposite velocity when hits a horizontal bound
    if (this.center.dy - radius < boundOffset ||
        this.center.dy > size.height - radius - boundOffset) {
      this.veloY *= -1;
    }
    //increase the circle size until this radius is hit
    if (this.radius != radiusBound) {
      this.radius = radiusScale * radiusBound;
    }
    //update the circles center postion for next frame
    this.center = this.center.translate(veloX, veloY);
  }

  ///this should be used for debug purposes only
  show(Canvas canvas, Paint paint) {
    canvas.drawCircle(this.center, this.radius, paint);
  }
}
