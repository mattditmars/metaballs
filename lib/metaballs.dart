import 'dart:math';

import 'package:flutter/material.dart';
import 'package:metaballs/classes/blob.dart';
import 'package:metaballs/metaballs_painter.dart';

class Metaballs extends StatefulWidget {
  @override
  _MetaballsState createState() => _MetaballsState();
}

class _MetaballsState extends State<Metaballs> with TickerProviderStateMixin {
  List<Blob> blobs;

  Random rng = Random(DateTime.now().millisecondsSinceEpoch);
  Animation<double> _endlessAnimation;
  AnimationController _endlessController;
  Tween<double> _endlessTween = Tween(begin: 0, end: 1);

  double canvasSize = 400;

  @override
  void initState() {
    super.initState();
    //More blobs = larger metaball
    blobs = [
      Blob(rng.nextDouble(), rng.nextDouble(), 25,
          Offset(canvasSize / 2, canvasSize / 2)),
      Blob(rng.nextDouble(), rng.nextDouble(), 25,
          Offset(canvasSize / 2, canvasSize / 2)),
      Blob(rng.nextDouble(), rng.nextDouble(), 25,
          Offset(canvasSize / 2, canvasSize / 2)),
      Blob(rng.nextDouble(), rng.nextDouble(), 25,
          Offset(canvasSize / 2, canvasSize / 2)),
      Blob(rng.nextDouble(), rng.nextDouble(), 25,
          Offset(canvasSize / 2, canvasSize / 2)),
      Blob(0.0, 0.0, 0, Offset(canvasSize / 2, canvasSize / 2)),
    ];

    _endlessController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );

    // This creates an endless animation that will call setState every time
    // the animation value changes. We need to do this to make sure the
    // painter redraws every frame.
    _endlessAnimation = _endlessTween.animate(
        CurvedAnimation(parent: _endlessController, curve: Curves.easeOutQuad))
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _endlessController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _endlessController.forward();
        }
      });

    _endlessController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Center(
          child: SizedBox.fromSize(
              size: Size.square(canvasSize),
              child: CustomPaint(
                painter: MetaballsPainter(blobs, _endlessAnimation.value),
              )),
        ),
      ),
    );
  }
}
