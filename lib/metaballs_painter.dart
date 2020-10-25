import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:metaballs/classes/blob.dart';
import 'package:metaballs/classes/corner.dart';

class MetaballsPainter extends CustomPainter {
  List<Blob> _blobs;
  List<Offset> _marchingOffsets = [];
  double _resolution = 0;

  /// radius that determines the size of the blobs for them to animate larger
  double _circleRadius;
  Path _path = Path();

  static int _numHorizontalPoints = 150;
  static int _numVerticalPoints = 150;
  var points = List.generate(
      _numVerticalPoints + 1, (i) => List(_numHorizontalPoints + 1),
      growable: false);

  MetaballsPainter(this._blobs, this._circleRadius);

  @override
  void paint(Canvas canvas, Size size) {
    _resolution = size.width / _numHorizontalPoints;

    Paint circPaint = Paint()
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.red
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 22.0);

    _populateCornersAndSamples();

    // Loop through the grid, get the 4 points of the grid square and pass the
    // marching value into the marching square function
    for (var i = 0; i < _numHorizontalPoints; i++) {
      for (var j = 0; j < _numVerticalPoints; j++) {
        Corner topLeft = points[i][j];
        Corner topRight = points[i + 1][j];
        Corner bottomLeft = points[i][j + 1];
        Corner bottomRight = points[i + 1][j + 1];

        int marchingValue = _getMarchingValue(
          topLeft.onOrOff,
          topRight.onOrOff,
          bottomRight.onOrOff,
          bottomLeft.onOrOff,
        );

        _addMarchingSquareOffsets(
            marchingValue, topLeft, topRight, bottomRight, bottomLeft);
      }
    }

    // Algorithm that takes an unsorted list of offsets and sorts them in such
    // a way that a Path can be drawn around the edge on the metaball shape.
    _orderOffsetsForDrawingPath();

    // Loop through the now ordered marchingOffsets list and draw the path.
    _createOrderedPath();

    _path.close();
    canvas.drawPath(_path, circPaint);

    // Update the blobs every frame to animate them
    _updateBlobs(size, _circleRadius);
  }

  //HELPER FUNCTIONS

  void _updateBlobs(Size size, double circleRadius) {
    for (var blob in this._blobs) {
      blob.update(size, circleRadius);
      //call blob.show() here if you want to see the underlying circles for
      //debug purposes
    }
  }

  void _createOrderedPath() {
    if (_marchingOffsets.isNotEmpty) {
      _path.moveTo(_marchingOffsets.first.dx, _marchingOffsets.first.dy);
      for (var i = 1; i < _marchingOffsets.length; i++) {
        Offset drawPoint = _marchingOffsets[i];
        _path.lineTo(drawPoint.dx, drawPoint.dy);
      }
    }
  }

  void _orderOffsetsForDrawingPath() {
    if (_marchingOffsets.isNotEmpty) {
      for (var i = 0; i < _marchingOffsets.length - 1; i++) {
        Offset currentOffset = _marchingOffsets[i];
        Offset closestOffset = _marchingOffsets[i + 1];

        double smallestDistance = double.infinity;
        int indexToSwap = i + 1;

        for (var j = i + 1; j < _marchingOffsets.length; j++) {
          // This is the offset we will compare against currentOffset in this
          // iteration of the loop
          Offset compareOffset = _marchingOffsets[j];

          // The next closest point will never be further than this, optimization
          if ((compareOffset.dx - currentOffset.dx).abs() < 1.5 * _resolution) {
            if ((compareOffset.dy - currentOffset.dy).abs() <
                1.5 * _resolution) {
              double distBetween = (compareOffset - currentOffset).distance;
              if (distBetween < smallestDistance) {
                smallestDistance = distBetween;
                closestOffset = compareOffset;
                indexToSwap = j;
              }
            }
          }
        }
        // Simple swap algorithm to reorder the list in place
        Offset auxOff = _marchingOffsets[i + 1];
        _marchingOffsets[i + 1] = closestOffset;
        _marchingOffsets[indexToSwap] = auxOff;
      }
    }
  }

  ///
  /// Starting from nW corner value and progressing clock wise around the imagined
  /// square the 4 values create. Get the decimal equivalent to the 4 bit binary
  /// number the 4 values create.
  ///
  int _getMarchingValue(int nW, int nE, int sE, int sW) {
    return (nW * 8) + (nE * 4) + (sE * 2) + (sW * 1);
  }

  ///
  /// Populate the points array with corners and their sample values based on
  /// their location compared to the blobs.
  ///
  void _populateCornersAndSamples() {
    for (var i = 0; i < _numHorizontalPoints + 1; i++) {
      for (var j = 0; j < _numVerticalPoints + 1; j++) {
        Offset point = Offset(i * _resolution, j * _resolution);
        double sampleValue = _metaballSample(_blobs, point);
        Corner corner = Corner(point, sampleValue);
        points[i][j] = corner;
      }
    }
  }

  ///
  /// Loops [_marchingOffsets] to determine if [newPoint] already exists in
  /// the list.
  ///
  bool _checkDuplicate(Offset newPoint) {
    for (var i = 0; i < _marchingOffsets.length; i++) {
      Offset compare = _marchingOffsets[i];
      if (newPoint.dx == compare.dx && newPoint.dy == compare.dy) {
        return true;
      }
    }
    return false;
  }

  double _lerp(sample1, sample2) {
    double halfRes = _resolution / 2.0;
    if (sample1 == sample2) {
      return halfRes;
    }
    return (0 + (1 - 0) * (1 - sample1) / (sample2 - sample1) * halfRes);
  }

  ///
  /// Given [point] sums and returns the distances from all the blobs to that point
  ///
  double _metaballSample(List<Blob> blobs, Offset point) {
    double sum = 0;
    for (var blob in blobs) {
      var dx = point.dx - blob.center.dx;
      var dy = point.dy - blob.center.dy;

      var d2 = dx * dx + dy * dy;
      sum += (blob.radius * blob.radius) / d2;
    }
    return sum;
  }

  ///
  /// Based on [marchingValue], calculates offsets and add them to [_marchingOffsets]
  /// if the point doesnt already exist to avoid duplicates.
  ///
  _addMarchingSquareOffsets(
    int marchingValue,
    Corner topLeft,
    Corner topRight,
    Corner bottomRight,
    Corner bottomLeft,
  ) {
    //no need for SE location
    Offset nW = topLeft.position;
    Offset nE = topRight.position;
    Offset sW = bottomLeft.position;

    switch (marchingValue) {
      case 1:
      case 14:
        Offset p1 = Offset(
          nW.dx,
          nW.dy + _lerp(topLeft.sampleValue, bottomLeft.sampleValue),
        );
        Offset p2 = Offset(
          sW.dx + _lerp(bottomLeft.sampleValue, bottomRight.sampleValue),
          sW.dy,
        );
        if (!_checkDuplicate(p1)) {
          _marchingOffsets.add(p1);
        }
        if (!_checkDuplicate(p2)) {
          _marchingOffsets.add(p2);
        }
        break;
      case 2:
      case 13:
        Offset p1 = Offset(
          nE.dx,
          nE.dy + _lerp(topRight.sampleValue, bottomRight.sampleValue),
        );
        Offset p2 = Offset(
          sW.dx + _lerp(bottomLeft.sampleValue, bottomRight.sampleValue),
          sW.dy,
        );
        if (!_checkDuplicate(p1)) {
          _marchingOffsets.add(p1);
        }
        if (!_checkDuplicate(p2)) {
          _marchingOffsets.add(p2);
        }
        break;
      case 3:
      case 12:
        Offset p1 = Offset(
          nW.dx,
          nW.dy + _lerp(topLeft.sampleValue, bottomLeft.sampleValue),
        );
        Offset p2 = Offset(
          nE.dx,
          nE.dy + _lerp(topRight.sampleValue, bottomRight.sampleValue),
        );
        if (!_checkDuplicate(p1)) {
          _marchingOffsets.add(p1);
        }
        if (!_checkDuplicate(p2)) {
          _marchingOffsets.add(p2);
        }
        break;
      case 4:
      case 11:
        Offset p1 = Offset(
          nW.dx + _lerp(topLeft.sampleValue, topRight.sampleValue),
          nW.dy,
        );
        Offset p2 = Offset(
          nE.dx,
          nE.dy + _lerp(topRight.sampleValue, bottomRight.sampleValue),
        );
        if (!_checkDuplicate(p1)) {
          _marchingOffsets.add(p1);
        }
        if (!_checkDuplicate(p2)) {
          _marchingOffsets.add(p2);
        }
        break;
      case 6:
      case 9:
        Offset p1 = Offset(
          nW.dx + _lerp(topLeft.sampleValue, topRight.sampleValue),
          nW.dy,
        );
        Offset p2 = Offset(
          sW.dx + _lerp(bottomLeft.sampleValue, bottomRight.sampleValue),
          sW.dy,
        );
        if (!_checkDuplicate(p1)) {
          _marchingOffsets.add(p1);
        }
        if (!_checkDuplicate(p2)) {
          _marchingOffsets.add(p2);
        }
        break;
      case 7:
      case 8:
        Offset p1 = Offset(
          nW.dx,
          nW.dy + _lerp(topLeft.sampleValue, bottomLeft.sampleValue),
        );
        Offset p2 = Offset(
          nW.dx + _lerp(topLeft.sampleValue, topRight.sampleValue),
          nW.dy,
        );
        if (!_checkDuplicate(p1)) {
          _marchingOffsets.add(p1);
        }
        if (!_checkDuplicate(p2)) {
          _marchingOffsets.add(p2);
        }
        break;
      default:
        break;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    //no need to check old delegate, this needs to update every frame
    return true;
  }
}
