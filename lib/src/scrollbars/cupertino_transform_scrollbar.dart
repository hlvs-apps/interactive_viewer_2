library interactive_viewer_2;
// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'scrollbar_painter.dart';

import 'transform_scrollbar_controller.dart';

// All values eyeballed.
const double _kScrollbarMinLength = 36.0;
const double _kScrollbarMinOverscrollLength = 8.0;
const Duration _kScrollbarTimeToFade = Duration(milliseconds: 1200);
const Duration _kScrollbarFadeDuration = Duration(milliseconds: 250);
const Duration _kScrollbarResizeDuration = Duration(milliseconds: 100);

// Extracted from iOS 13.1 beta using Debug View Hierarchy.
const Color _kScrollbarColor = CupertinoDynamicColor.withBrightness(
  color: Color(0x59000000),
  darkColor: Color(0x80FFFFFF),
);

// This is the amount of space from the top of a vertical scrollbar to the
// top edge of the scrollable, measured when the vertical scrollbar overscrolls
// to the top.
// TODO(LongCatIsLooong): fix https://github.com/flutter/flutter/issues/32175
const double _kScrollbarMainAxisMargin = 3.0;
const double _kScrollbarCrossAxisMargin = 3.0;

class CupertinoScrollbarTransformController
    extends RawTransformScrollbarController {
  CupertinoScrollbarTransformController({
    required super.vsync,
    required super.controlInterface,
    bool? thumbVisibility,
    super.thickness = defaultThickness,
    this.thicknessWhileDragging = defaultThicknessWhileDragging,
    Radius super.radius = defaultRadius,
    this.radiusWhileDragging = defaultRadiusWhileDragging,
  })  : assert(thickness! < double.infinity),
        assert(thicknessWhileDragging < double.infinity),
        _thicknessAnimationControllerV = AnimationController(
          vsync: vsync,
          duration: _kScrollbarResizeDuration,
        ),
        _thicknessAnimationControllerH = AnimationController(
          vsync: vsync,
          duration: _kScrollbarResizeDuration,
        ),
        super(
          thumbVisibility: thumbVisibility ?? false,
          fadeDuration: _kScrollbarFadeDuration,
          timeToFade: _kScrollbarTimeToFade,
          pressDuration: const Duration(milliseconds: 100),
        ) {
    _thicknessAnimationControllerV.addListener(() {
      updateScrollbarPainter(true);
    });
    _thicknessAnimationControllerH.addListener(() {
      updateScrollbarPainter(false);
    });
  }

  /// Default value for [thickness] if it's not specified in [CupertinoScrollbar].
  static const double defaultThickness = 6;

  /// Default value for [thicknessWhileDragging] if it's not specified in
  /// [CupertinoScrollbar].
  static const double defaultThicknessWhileDragging = 8.0;

  /// Default value for [radius] if it's not specified in [CupertinoScrollbar].
  static const Radius defaultRadius = Radius.circular(1.5);

  /// Default value for [radiusWhileDragging] if it's not specified in
  /// [CupertinoScrollbar].
  static const Radius defaultRadiusWhileDragging = Radius.circular(4.0);

  /// The thickness of the scrollbar when it's being dragged by the user.
  ///
  /// When the user starts dragging the scrollbar, the thickness will animate
  /// from [thickness] to this value, then animate back when the user stops
  /// dragging the scrollbar.
  final double thicknessWhileDragging;

  /// The radius of the scrollbar edges when the scrollbar is being dragged by
  /// the user.
  ///
  /// When the user starts dragging the scrollbar, the radius will animate
  /// from [radius] to this value, then animate back when the user stops
  /// dragging the scrollbar.
  final Radius radiusWhileDragging;

  final AnimationController _thicknessAnimationControllerV;
  final AnimationController _thicknessAnimationControllerH;

  double get _thicknessV {
    return thickness! +
        _thicknessAnimationControllerV.value *
            (thicknessWhileDragging - thickness!);
  }

  double get _thicknessH {
    return thickness! +
        _thicknessAnimationControllerH.value *
            (thicknessWhileDragging - thickness!);
  }

  Radius get _radiusV {
    return Radius.lerp(
        radius, radiusWhileDragging, _thicknessAnimationControllerV.value)!;
  }

  Radius get _radiusH {
    return Radius.lerp(
        radius, radiusWhileDragging, _thicknessAnimationControllerH.value)!;
  }

  @override
  void updateScrollbarPainter(bool vertical) {
    PublicScrollbarPainter scrollbarPainter =
        vertical ? verticalScrollbar : horizontalScrollbar;
    scrollbarPainter
      ..color = CupertinoDynamicColor.resolve(_kScrollbarColor, context)
      ..textDirection = Directionality.of(context)
      ..thickness = vertical ? _thicknessV : _thicknessH
      ..mainAxisMargin = _kScrollbarMainAxisMargin
      ..crossAxisMargin = _kScrollbarCrossAxisMargin
      ..radius = vertical ? _radiusV : _radiusH
      ..padding = MediaQuery.paddingOf(context)
      ..minLength = _kScrollbarMinLength
      ..minOverscrollLength = _kScrollbarMinOverscrollLength;
  }

  double _pressStartAxisPositionV = 0.0;
  double _pressStartAxisPositionH = 0.0;

  // Long press event callbacks handle the gesture where the user long presses
  // on the scrollbar thumb and then drags the scrollbar without releasing.

  @override
  void handleThumbPressStartVertical(Offset position) {
    super.handleThumbPressStartVertical(position);
    _pressStartAxisPositionV = position.dy;
  }

  @override
  void handleThumbPressStartHorizontal(Offset position) {
    super.handleThumbPressStartHorizontal(position);
    _pressStartAxisPositionH = position.dx;
  }

  @override
  void handleThumbPressVertical() {
    super.handleThumbPressVertical();
    _thicknessAnimationControllerV.forward().then<void>(
          (_) => HapticFeedback.mediumImpact(),
        );
  }

  @override
  void handleThumbPressHorizontal() {
    super.handleThumbPressHorizontal();
    _thicknessAnimationControllerH.forward().then<void>(
          (_) => HapticFeedback.mediumImpact(),
        );
  }

  @override
  void handleThumbPressEndVertical(Offset position, Velocity velocity) {
    _thicknessAnimationControllerV.reverse();
    super.handleThumbPressEndVertical(position, velocity);
    if (velocity.pixelsPerSecond.dy.abs() < 10 &&
        (position.dy - _pressStartAxisPositionV).abs() > 0) {
      HapticFeedback.mediumImpact();
    }
  }

  @override
  void handleThumbPressEndHorizontal(Offset position, Velocity velocity) {
    _thicknessAnimationControllerH.reverse();
    super.handleThumbPressEndHorizontal(position, velocity);
    if (velocity.pixelsPerSecond.dx.abs() < 10 &&
        (position.dx - _pressStartAxisPositionH).abs() > 0) {
      HapticFeedback.mediumImpact();
    }
  }

  @override
  void dispose() {
    _thicknessAnimationControllerV.dispose();
    _thicknessAnimationControllerH.dispose();
    super.dispose();
  }
}
