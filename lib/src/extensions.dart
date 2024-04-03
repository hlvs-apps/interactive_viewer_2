library interactive_viewer_2;

import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'dart:math' as math;

extension ScaleUtilities on Matrix4 {
  double getScaleOnXAxis() {
    Float64List m4storage = storage;
    final scaleX = math.sqrt(m4storage[0] * m4storage[0] +
        m4storage[1] * m4storage[1] +
        m4storage[2] * m4storage[2]);
    return scaleX;
  }

  double getScaleOnYAxis() {
    Float64List m4storage = storage;
    final scaleY = math.sqrt(m4storage[4] * m4storage[4] +
        m4storage[5] * m4storage[5] +
        m4storage[6] * m4storage[6]);
    return scaleY;
  }

  /// Returns the scale on the z-axis.
  /// The z-axis doesnt get changed by translation or rotation, so the scale on the z-axis is the original intended scale.
  /// This is useful for stretching effect on the x and y axis, which is applied to simulate for example a over-scroll effect.
  double getScaleOnZAxis() {
    Float64List m4storage = storage;
    final scaleZSq = m4storage[8] * m4storage[8] +
        m4storage[9] * m4storage[9] +
        m4storage[10] * m4storage[10];
    return math.sqrt(scaleZSq);
  }

  void resetToZScale() {
    final scaleX = getScaleOnXAxis();
    final scaleY = getScaleOnYAxis();
    final scaleZ = getScaleOnZAxis();
    if (scaleX != scaleZ) {
      scale(scaleX / scaleZ, 1.0, 1.0);
    }
    if (scaleY != scaleZ) {
      scale(1.0, scaleY / scaleZ, 1.0);
    }
  }
}

extension LocalOffset on Offset {
  Offset toLocal(BuildContext context) {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    return renderBox.globalToLocal(this);
  }
}
