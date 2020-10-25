import 'package:flutter/material.dart';
import 'package:metaballs/metaballs.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Metaballs',
      home: Metaballs(),
    );
  }
}
