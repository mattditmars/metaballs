import 'package:flutter/material.dart';

class Corner {
  Offset position;
  double sampleValue;

  ///whether or not the corner is in the metaball
  int get onOrOff => sampleValue >= 1 ? 1 : 0;

  Corner(this.position, this.sampleValue);
}
