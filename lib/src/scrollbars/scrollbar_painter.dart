library interactive_viewer_2_src;
// Copied from scrollbar.dart in flutter source code.
// Only made one private method public, to get thumb extend for paging

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

const double _kMinThumbExtent = 18.0;
const double _kMinInteractiveSize = 48.0;
const double _kScrollbarThickness = 6.0;

/// Paints a scrollbar's track and thumb.
///
/// The size of the scrollbar along its scroll direction is typically
/// proportional to the percentage of content completely visible on screen,
/// as long as its size isn't less than [minLength] and it isn't overscrolling.
///
/// Unlike [CustomPainter]s that subclasses [CustomPainter] and only repaint
/// when [shouldRepaint] returns true (which requires this [CustomPainter] to
/// be rebuilt), this painter has the added optimization of repainting and not
/// rebuilding when:
///
///  * the scroll position changes; and
///  * when the scrollbar fades away.
///
/// Calling [update] with the new [ScrollMetrics] will repaint the new scrollbar
/// position.
///
/// Updating the value on the provided [fadeoutOpacityAnimation] will repaint
/// with the new opacity.
///
/// You must call [dispose] on this [PublicScrollbarPainter] when it's no longer used.
///
/// See also:
///
///  * [Scrollbar] for a widget showing a scrollbar around a [Scrollable] in the
///    Material Design style.
///  * [CupertinoScrollbar] for a widget showing a scrollbar around a
///    [Scrollable] in the iOS style.
class PublicScrollbarPainter extends ChangeNotifier implements CustomPainter {
  /// Creates a scrollbar with customizations given by construction arguments.
  PublicScrollbarPainter({
    required Color color,
    required this.fadeoutOpacityAnimation,
    Color trackColor = const Color(0x00000000),
    Color trackBorderColor = const Color(0x00000000),
    TextDirection? textDirection,
    double thickness = _kScrollbarThickness,
    EdgeInsets padding = EdgeInsets.zero,
    double mainAxisMargin = 0.0,
    double crossAxisMargin = 0.0,
    Radius? radius,
    Radius? trackRadius,
    OutlinedBorder? shape,
    double minLength = _kMinThumbExtent,
    double? minOverscrollLength,
    ScrollbarOrientation? scrollbarOrientation,
    bool ignorePointer = false,
  })  : assert(radius == null || shape == null),
        assert(minLength >= 0),
        assert(minOverscrollLength == null || minOverscrollLength <= minLength),
        assert(minOverscrollLength == null || minOverscrollLength >= 0),
        assert(padding.isNonNegative),
        _color = color,
        _textDirection = textDirection,
        _thickness = thickness,
        _radius = radius,
        _shape = shape,
        _padding = padding,
        _mainAxisMargin = mainAxisMargin,
        _crossAxisMargin = crossAxisMargin,
        _minLength = minLength,
        _trackColor = trackColor,
        _trackBorderColor = trackBorderColor,
        _trackRadius = trackRadius,
        _scrollbarOrientation = scrollbarOrientation,
        _minOverscrollLength = minOverscrollLength ?? minLength,
        _ignorePointer = ignorePointer {
    fadeoutOpacityAnimation.addListener(notifyListeners);
  }

  /// [Color] of the thumb. Mustn't be null.
  Color get color => _color;
  Color _color;
  set color(Color value) {
    if (color == value) {
      return;
    }

    _color = value;
    notifyListeners();
  }

  /// [Color] of the track. Mustn't be null.
  Color get trackColor => _trackColor;
  Color _trackColor;
  set trackColor(Color value) {
    if (trackColor == value) {
      return;
    }

    _trackColor = value;
    notifyListeners();
  }

  /// [Color] of the track border. Mustn't be null.
  Color get trackBorderColor => _trackBorderColor;
  Color _trackBorderColor;
  set trackBorderColor(Color value) {
    if (trackBorderColor == value) {
      return;
    }

    _trackBorderColor = value;
    notifyListeners();
  }

  /// [Radius] of corners of the Scrollbar's track.
  ///
  /// Scrollbar's track will be rectangular if [trackRadius] is null.
  Radius? get trackRadius => _trackRadius;
  Radius? _trackRadius;
  set trackRadius(Radius? value) {
    if (trackRadius == value) {
      return;
    }

    _trackRadius = value;
    notifyListeners();
  }

  /// [TextDirection] of the [BuildContext] which dictates the side of the
  /// screen the scrollbar appears in (the trailing side). Must be set prior to
  /// calling paint.
  TextDirection? get textDirection => _textDirection;
  TextDirection? _textDirection;
  set textDirection(TextDirection? value) {
    assert(value != null);
    if (textDirection == value) {
      return;
    }

    _textDirection = value;
    notifyListeners();
  }

  /// Thickness of the scrollbar in its cross-axis in logical pixels. Mustn't be null.
  double get thickness => _thickness;
  double _thickness;
  set thickness(double value) {
    if (thickness == value) {
      return;
    }

    _thickness = value;
    notifyListeners();
  }

  /// An opacity [Animation] that dictates the opacity of the thumb.
  /// Changes in value of this [Listenable] will automatically trigger repaints.
  /// Mustn't be null.
  final Animation<double> fadeoutOpacityAnimation;

  /// Distance from the scrollbar thumb's start and end to the edge of the
  /// viewport in logical pixels. It affects the amount of available paint area.
  ///
  /// The scrollbar track consumes this space.
  ///
  /// Mustn't be null and defaults to 0.
  double get mainAxisMargin => _mainAxisMargin;
  double _mainAxisMargin;
  set mainAxisMargin(double value) {
    if (mainAxisMargin == value) {
      return;
    }

    _mainAxisMargin = value;
    notifyListeners();
  }

  /// Distance from the scrollbar thumb to the nearest cross axis edge
  /// in logical pixels.
  ///
  /// The scrollbar track consumes this space.
  ///
  /// Defaults to zero.
  double get crossAxisMargin => _crossAxisMargin;
  double _crossAxisMargin;
  set crossAxisMargin(double value) {
    if (crossAxisMargin == value) {
      return;
    }

    _crossAxisMargin = value;
    notifyListeners();
  }

  /// [Radius] of corners if the scrollbar should have rounded corners.
  ///
  /// Scrollbar will be rectangular if [radius] is null.
  Radius? get radius => _radius;
  Radius? _radius;
  set radius(Radius? value) {
    assert(shape == null || value == null);
    if (radius == value) {
      return;
    }

    _radius = value;
    notifyListeners();
  }

  /// The [OutlinedBorder] of the scrollbar's thumb.
  ///
  /// Only one of [radius] and [shape] may be specified. For a rounded rectangle,
  /// it's simplest to just specify [radius]. By default, the scrollbar thumb's
  /// shape is a simple rectangle.
  ///
  /// If [shape] is specified, the thumb will take the shape of the passed
  /// [OutlinedBorder] and fill itself with [color] (or grey if it
  /// is unspecified).
  ///
  OutlinedBorder? get shape => _shape;
  OutlinedBorder? _shape;
  set shape(OutlinedBorder? value) {
    assert(radius == null || value == null);
    if (shape == value) {
      return;
    }

    _shape = value;
    notifyListeners();
  }

  /// The amount of space by which to inset the scrollbar's start and end, as
  /// well as its side to the nearest edge, in logical pixels.
  ///
  /// This is typically set to the current [MediaQueryData.padding] to avoid
  /// partial obstructions such as display notches. If you only want additional
  /// margins around the scrollbar, see [mainAxisMargin].
  ///
  /// Defaults to [EdgeInsets.zero]. Offsets from all four directions must be
  /// greater than or equal to zero.
  EdgeInsets get padding => _padding;
  EdgeInsets _padding;
  set padding(EdgeInsets value) {
    if (padding == value) {
      return;
    }

    _padding = value;
    notifyListeners();
  }

  /// The preferred smallest size the scrollbar thumb can shrink to when the total
  /// scrollable extent is large, the current visible viewport is small, and the
  /// viewport is not overscrolled.
  ///
  /// The size of the scrollbar may shrink to a smaller size than [minLength] to
  /// fit in the available paint area. E.g., when [minLength] is
  /// `double.infinity`, it will not be respected if
  /// [ScrollMetrics.viewportDimension] and [mainAxisMargin] are finite.
  ///
  /// Mustn't be null and the value has to be greater or equal to
  /// [minOverscrollLength], which in turn is >= 0. Defaults to 18.0.
  double get minLength => _minLength;
  double _minLength;
  set minLength(double value) {
    if (minLength == value) {
      return;
    }

    _minLength = value;
    notifyListeners();
  }

  /// The preferred smallest size the scrollbar thumb can shrink to when viewport is
  /// overscrolled.
  ///
  /// When overscrolling, the size of the scrollbar may shrink to a smaller size
  /// than [minOverscrollLength] to fit in the available paint area. E.g., when
  /// [minOverscrollLength] is `double.infinity`, it will not be respected if
  /// the [ScrollMetrics.viewportDimension] and [mainAxisMargin] are finite.
  ///
  /// The value is less than or equal to [minLength] and greater than or equal to 0.
  /// When null, it will default to the value of [minLength].
  double get minOverscrollLength => _minOverscrollLength;
  double _minOverscrollLength;
  set minOverscrollLength(double value) {
    if (minOverscrollLength == value) {
      return;
    }

    _minOverscrollLength = value;
    notifyListeners();
  }

  /// {@template flutter.widgets.Scrollbar.scrollbarOrientation}
  /// Dictates the orientation of the scrollbar.
  ///
  /// [ScrollbarOrientation.top] places the scrollbar on top of the screen.
  /// [ScrollbarOrientation.bottom] places the scrollbar on the bottom of the screen.
  /// [ScrollbarOrientation.left] places the scrollbar on the left of the screen.
  /// [ScrollbarOrientation.right] places the scrollbar on the right of the screen.
  ///
  /// [ScrollbarOrientation.top] and [ScrollbarOrientation.bottom] can only be
  /// used with a vertical scroll.
  /// [ScrollbarOrientation.left] and [ScrollbarOrientation.right] can only be
  /// used with a horizontal scroll.
  ///
  /// For a vertical scroll the orientation defaults to
  /// [ScrollbarOrientation.right] for [TextDirection.ltr] and
  /// [ScrollbarOrientation.left] for [TextDirection.rtl].
  /// For a horizontal scroll the orientation defaults to [ScrollbarOrientation.bottom].
  /// {@endtemplate}
  ScrollbarOrientation? get scrollbarOrientation => _scrollbarOrientation;
  ScrollbarOrientation? _scrollbarOrientation;
  set scrollbarOrientation(ScrollbarOrientation? value) {
    if (scrollbarOrientation == value) {
      return;
    }

    _scrollbarOrientation = value;
    notifyListeners();
  }

  /// Whether the painter will be ignored during hit testing.
  bool get ignorePointer => _ignorePointer;
  bool _ignorePointer;
  set ignorePointer(bool value) {
    if (ignorePointer == value) {
      return;
    }

    _ignorePointer = value;
    notifyListeners();
  }

  // - Scrollbar Details

  Rect? _trackRect;
  // The full painted length of the track
  double get _trackExtent =>
      _lastMetrics!.viewportDimension - _totalTrackMainAxisOffsets;
  // The full length of the track that the thumb can travel
  double get _traversableTrackExtent => _trackExtent - (2 * mainAxisMargin);
  // Track Offsets
  // The track is offset by only padding.
  double get _totalTrackMainAxisOffsets =>
      _isVertical ? padding.vertical : padding.horizontal;
  double get _leadingTrackMainAxisOffset {
    switch (_resolvedOrientation) {
      case ScrollbarOrientation.left:
      case ScrollbarOrientation.right:
        return padding.top;
      case ScrollbarOrientation.top:
      case ScrollbarOrientation.bottom:
        return padding.left;
    }
  }

  Rect? _thumbRect;
  // The current scroll position + _leadingThumbMainAxisOffset
  late double thumbOffset;
  // The fraction visible in relation to the traversable length of the track.
  late double _thumbExtent;
  // Thumb Offsets
  // The thumb is offset by padding and margins.
  double get _leadingThumbMainAxisOffset {
    switch (_resolvedOrientation) {
      case ScrollbarOrientation.left:
      case ScrollbarOrientation.right:
        return padding.top + mainAxisMargin;
      case ScrollbarOrientation.top:
      case ScrollbarOrientation.bottom:
        return padding.left + mainAxisMargin;
    }
  }

  void _setThumbExtent() {
    // Thumb extent reflects fraction of content visible, as long as this
    // isn't less than the absolute minimum size.
    // _totalContentExtent >= viewportDimension, so (_totalContentExtent - _mainAxisPadding) > 0
    final double fractionVisible = clampDouble(
      (_lastMetrics!.extentInside - _totalTrackMainAxisOffsets) /
          (_totalContentExtent - _totalTrackMainAxisOffsets),
      0.0,
      1.0,
    );

    final double thumbExtent = math.max(
      math.min(_traversableTrackExtent, minOverscrollLength),
      _traversableTrackExtent * fractionVisible,
    );

    final double fractionOverscrolled =
        1.0 - _lastMetrics!.extentInside / _lastMetrics!.viewportDimension;
    final double safeMinLength = math.min(minLength, _traversableTrackExtent);
    final double newMinLength = (_beforeExtent > 0 && _afterExtent > 0)
        // Thumb extent is no smaller than minLength if scrolling normally.
        ? safeMinLength
        // User is overscrolling. Thumb extent can be less than minLength
        // but no smaller than minOverscrollLength. We can't use the
        // fractionVisible to produce intermediate values between minLength and
        // minOverscrollLength when the user is transitioning from regular
        // scrolling to overscrolling, so we instead use the percentage of the
        // content that is still in the viewport to determine the size of the
        // thumb. iOS behavior appears to have the thumb reach its minimum size
        // with ~20% of overscroll. We map the percentage of minLength from
        // [0.8, 1.0] to [0.0, 1.0], so 0% to 20% of overscroll will produce
        // values for the thumb that range between minLength and the smallest
        // possible value, minOverscrollLength.
        : safeMinLength *
            (1.0 - clampDouble(fractionOverscrolled, 0.0, 0.2) / 0.2);

    // The `thumbExtent` should be no greater than `trackSize`, otherwise
    // the scrollbar may scroll towards the wrong direction.
    _thumbExtent =
        clampDouble(thumbExtent, newMinLength, _traversableTrackExtent);
  }

  // - Scrollable Details

  ScrollMetrics? _lastMetrics;
  bool get _lastMetricsAreScrollable =>
      _lastMetrics!.minScrollExtent != _lastMetrics!.maxScrollExtent;
  AxisDirection? _lastAxisDirection;

  bool get _isVertical =>
      _lastAxisDirection == AxisDirection.down ||
      _lastAxisDirection == AxisDirection.up;
  bool get _isReversed =>
      _lastAxisDirection == AxisDirection.up ||
      _lastAxisDirection == AxisDirection.left;
  // The amount of scroll distance before and after the current position.
  double get _beforeExtent =>
      _isReversed ? _lastMetrics!.extentAfter : _lastMetrics!.extentBefore;
  double get _afterExtent =>
      _isReversed ? _lastMetrics!.extentBefore : _lastMetrics!.extentAfter;

  // The total size of the scrollable content.
  double get _totalContentExtent {
    return _lastMetrics!.maxScrollExtent -
        _lastMetrics!.minScrollExtent +
        _lastMetrics!.viewportDimension;
  }

  ScrollbarOrientation get _resolvedOrientation {
    if (scrollbarOrientation == null) {
      if (_isVertical) {
        return textDirection == TextDirection.ltr
            ? ScrollbarOrientation.right
            : ScrollbarOrientation.left;
      }
      return ScrollbarOrientation.bottom;
    }
    return scrollbarOrientation!;
  }

  void _debugAssertIsValidOrientation(ScrollbarOrientation orientation) {
    assert(() {
      bool isVerticalOrientation(ScrollbarOrientation orientation) =>
          orientation == ScrollbarOrientation.left ||
          orientation == ScrollbarOrientation.right;
      return (_isVertical && isVerticalOrientation(orientation)) ||
          (!_isVertical && !isVerticalOrientation(orientation));
    }(),
        'The given ScrollbarOrientation: $orientation is incompatible with the '
        'current AxisDirection: $_lastAxisDirection.');
  }

  // - Updating

  /// Update with new [ScrollMetrics]. If the metrics change, the scrollbar will
  /// show and redraw itself based on these new metrics.
  ///
  /// The scrollbar will remain on screen.
  void update(
    ScrollMetrics metrics,
    AxisDirection axisDirection,
  ) {
    if (_lastMetrics != null &&
        _lastMetrics!.extentBefore == metrics.extentBefore &&
        _lastMetrics!.extentInside == metrics.extentInside &&
        _lastMetrics!.extentAfter == metrics.extentAfter &&
        _lastAxisDirection == axisDirection) {
      return;
    }

    final ScrollMetrics? oldMetrics = _lastMetrics;
    _lastMetrics = metrics;
    _lastAxisDirection = axisDirection;

    bool needPaint(ScrollMetrics? metrics) =>
        metrics != null && metrics.maxScrollExtent > metrics.minScrollExtent;
    if (!needPaint(oldMetrics) && !needPaint(metrics)) {
      return;
    }
    notifyListeners();
  }

  /// Update and redraw with new scrollbar thickness and radius.
  void updateThickness(double nextThickness, Radius nextRadius) {
    thickness = nextThickness;
    radius = nextRadius;
  }

  // - Painting

  Paint get _paintThumb {
    return Paint()
      ..color =
          color.withOpacity(color.opacity * fadeoutOpacityAnimation.value);
  }

  Paint _paintTrack({bool isBorder = false}) {
    if (isBorder) {
      return Paint()
        ..color = trackBorderColor.withOpacity(
            trackBorderColor.opacity * fadeoutOpacityAnimation.value)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
    }
    return Paint()
      ..color = trackColor
          .withOpacity(trackColor.opacity * fadeoutOpacityAnimation.value);
  }

  void _paintScrollbar(Canvas canvas, Size size) {
    assert(
      textDirection != null,
      'A TextDirection must be provided before a Scrollbar can be painted.',
    );

    final double x, y;
    final Size thumbSize, trackSize;
    final Offset trackOffset, borderStart, borderEnd;
    _debugAssertIsValidOrientation(_resolvedOrientation);
    switch (_resolvedOrientation) {
      case ScrollbarOrientation.left:
        thumbSize = Size(thickness, _thumbExtent);
        trackSize = Size(thickness + 2 * crossAxisMargin, _trackExtent);
        x = crossAxisMargin + padding.left;
        y = thumbOffset;
        trackOffset = Offset(x - crossAxisMargin, _leadingTrackMainAxisOffset);
        borderStart = trackOffset + Offset(trackSize.width, 0.0);
        borderEnd = Offset(
            trackOffset.dx + trackSize.width, trackOffset.dy + _trackExtent);
      case ScrollbarOrientation.right:
        thumbSize = Size(thickness, _thumbExtent);
        trackSize = Size(thickness + 2 * crossAxisMargin, _trackExtent);
        x = size.width - thickness - crossAxisMargin - padding.right;
        y = thumbOffset;
        trackOffset = Offset(x - crossAxisMargin, _leadingTrackMainAxisOffset);
        borderStart = trackOffset;
        borderEnd = Offset(trackOffset.dx, trackOffset.dy + _trackExtent);
      case ScrollbarOrientation.top:
        thumbSize = Size(_thumbExtent, thickness);
        trackSize = Size(_trackExtent, thickness + 2 * crossAxisMargin);
        x = thumbOffset;
        y = crossAxisMargin + padding.top;
        trackOffset = Offset(_leadingTrackMainAxisOffset, y - crossAxisMargin);
        borderStart = trackOffset + Offset(0.0, trackSize.height);
        borderEnd = Offset(
            trackOffset.dx + _trackExtent, trackOffset.dy + trackSize.height);
      case ScrollbarOrientation.bottom:
        thumbSize = Size(_thumbExtent, thickness);
        trackSize = Size(_trackExtent, thickness + 2 * crossAxisMargin);
        x = thumbOffset;
        y = size.height - thickness - crossAxisMargin - padding.bottom;
        trackOffset = Offset(_leadingTrackMainAxisOffset, y - crossAxisMargin);
        borderStart = trackOffset;
        borderEnd = Offset(trackOffset.dx + _trackExtent, trackOffset.dy);
    }

    // Whether we paint or not, calculating these rects allows us to hit test
    // when the scrollbar is transparent.
    _trackRect = trackOffset & trackSize;
    _thumbRect = Offset(x, y) & thumbSize;

    // Paint if the opacity dictates visibility
    if (fadeoutOpacityAnimation.value != 0.0) {
      // Track
      if (trackRadius == null) {
        canvas.drawRect(_trackRect!, _paintTrack());
      } else {
        canvas.drawRRect(
            RRect.fromRectAndRadius(_trackRect!, trackRadius!), _paintTrack());
      }
      // Track Border
      canvas.drawLine(borderStart, borderEnd, _paintTrack(isBorder: true));
      if (radius != null) {
        // Rounded rect thumb
        canvas.drawRRect(
            RRect.fromRectAndRadius(_thumbRect!, radius!), _paintThumb);
        return;
      }
      if (shape == null) {
        // Square thumb
        canvas.drawRect(_thumbRect!, _paintThumb);
        return;
      }
      // Custom-shaped thumb
      final Path outerPath = shape!.getOuterPath(_thumbRect!);
      canvas.drawPath(outerPath, _paintThumb);
      shape!.paint(canvas, _thumbRect!);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_lastAxisDirection == null ||
        _lastMetrics == null ||
        _lastMetrics!.maxScrollExtent <= _lastMetrics!.minScrollExtent) {
      return;
    }
    // Skip painting if there's not enough space.
    if (_traversableTrackExtent <= 0) {
      return;
    }
    // Do not paint a scrollbar if the scroll view is infinitely long.
    // TODO(Piinks): Special handling for infinite scroll views,
    //  https://github.com/flutter/flutter/issues/41434
    if (_lastMetrics!.maxScrollExtent.isInfinite) {
      return;
    }

    _setThumbExtent();
    final double thumbPositionOffset = getScrollToTrack(_lastMetrics!);
    thumbOffset = thumbPositionOffset + _leadingThumbMainAxisOffset;

    return _paintScrollbar(canvas, size);
  }

  // - Scroll Position Conversion

  /// Convert between a thumb track position and the corresponding scroll
  /// position.
  ///
  /// The `thumbOffsetLocal` argument is a position in the thumb track.
  double getTrackToScroll(double thumbOffsetLocal) {
    final double scrollableExtent =
        _lastMetrics!.maxScrollExtent - _lastMetrics!.minScrollExtent;
    final double thumbMovableExtent = _traversableTrackExtent - _thumbExtent;

    return scrollableExtent * thumbOffsetLocal / thumbMovableExtent;
  }

  /// The thumb's corresponding scroll offset in the track.
  double getThumbScrollOffset() {
    final double scrollableExtent =
        _lastMetrics!.maxScrollExtent - _lastMetrics!.minScrollExtent;

    final double fractionPast = (scrollableExtent > 0)
        ? clampDouble(_lastMetrics!.pixels / scrollableExtent, 0.0, 1.0)
        : 0;

    return fractionPast * (_traversableTrackExtent - _thumbExtent);
  }

  // Converts between a scroll position and the corresponding position in the
  // thumb track.
  double getScrollToTrack(ScrollMetrics metrics) {
    final double scrollableExtent =
        metrics.maxScrollExtent - metrics.minScrollExtent;

    final double fractionPast = (scrollableExtent > 0)
        ? clampDouble(
            (metrics.pixels - metrics.minScrollExtent) / scrollableExtent,
            0.0,
            1.0)
        : 0;

    return (_isReversed ? 1 - fractionPast : fractionPast) *
        (_traversableTrackExtent - _thumbExtent);
  }

  // - Hit Testing

  @override
  bool? hitTest(Offset? position) {
    // There is nothing painted to hit.
    if (_thumbRect == null) {
      return null;
    }

    // Interaction disabled.
    if (ignorePointer
        // The thumb is not able to be hit when transparent.
        ||
        fadeoutOpacityAnimation.value == 0.0
        // Not scrollable
        ||
        !_lastMetricsAreScrollable) {
      return false;
    }

    return _trackRect!.contains(position!);
  }

  /// Same as hitTest, but includes some padding when the [PointerEvent] is
  /// caused by [PointerDeviceKind.touch] to make sure that the region
  /// isn't too small to be interacted with by the user.
  ///
  /// The hit test area for hovering with [PointerDeviceKind.mouse] over the
  /// scrollbar also uses this extra padding. This is to make it easier to
  /// interact with the scrollbar by presenting it to the mouse for interaction
  /// based on proximity. When `forHover` is true, the larger hit test area will
  /// be used.
  bool hitTestInteractive(Offset position, PointerDeviceKind kind,
      {bool forHover = false}) {
    if (_trackRect == null) {
      // We have not computed the scrollbar position yet.
      return false;
    }
    if (ignorePointer) {
      return false;
    }

    if (!_lastMetricsAreScrollable) {
      return false;
    }

    final Rect interactiveRect = _trackRect!;
    final Rect paddedRect = interactiveRect.expandToInclude(
      Rect.fromCircle(
          center: _thumbRect!.center, radius: _kMinInteractiveSize / 2),
    );

    // The scrollbar is not able to be hit when transparent - except when
    // hovering with a mouse. This should bring the scrollbar into view so the
    // mouse can interact with it.
    if (fadeoutOpacityAnimation.value == 0.0) {
      if (forHover && kind == PointerDeviceKind.mouse) {
        return paddedRect.contains(position);
      }
      return false;
    }

    switch (kind) {
      case PointerDeviceKind.touch:
      case PointerDeviceKind.trackpad:
        return paddedRect.contains(position);
      case PointerDeviceKind.mouse:
      case PointerDeviceKind.stylus:
      case PointerDeviceKind.invertedStylus:
      case PointerDeviceKind.unknown:
        return interactiveRect.contains(position);
    }
  }

  /// Same as hitTestInteractive, but excludes the track portion of the scrollbar.
  /// Used to evaluate interactions with only the scrollbar thumb.
  bool hitTestOnlyThumbInteractive(Offset position, PointerDeviceKind kind) {
    if (_thumbRect == null) {
      return false;
    }
    if (ignorePointer) {
      return false;
    }
    // The thumb is not able to be hit when transparent.
    if (fadeoutOpacityAnimation.value == 0.0) {
      return false;
    }

    if (!_lastMetricsAreScrollable) {
      return false;
    }

    switch (kind) {
      case PointerDeviceKind.touch:
      case PointerDeviceKind.trackpad:
        final Rect touchThumbRect = _thumbRect!.expandToInclude(
          Rect.fromCircle(
              center: _thumbRect!.center, radius: _kMinInteractiveSize / 2),
        );
        return touchThumbRect.contains(position);
      case PointerDeviceKind.mouse:
      case PointerDeviceKind.stylus:
      case PointerDeviceKind.invertedStylus:
      case PointerDeviceKind.unknown:
        return _thumbRect!.contains(position);
    }
  }

  @override
  bool shouldRepaint(PublicScrollbarPainter oldDelegate) {
    // Should repaint if any properties changed.
    return color != oldDelegate.color ||
        trackColor != oldDelegate.trackColor ||
        trackBorderColor != oldDelegate.trackBorderColor ||
        textDirection != oldDelegate.textDirection ||
        thickness != oldDelegate.thickness ||
        fadeoutOpacityAnimation != oldDelegate.fadeoutOpacityAnimation ||
        mainAxisMargin != oldDelegate.mainAxisMargin ||
        crossAxisMargin != oldDelegate.crossAxisMargin ||
        radius != oldDelegate.radius ||
        trackRadius != oldDelegate.trackRadius ||
        shape != oldDelegate.shape ||
        padding != oldDelegate.padding ||
        minLength != oldDelegate.minLength ||
        minOverscrollLength != oldDelegate.minOverscrollLength ||
        scrollbarOrientation != oldDelegate.scrollbarOrientation ||
        ignorePointer != oldDelegate.ignorePointer;
  }

  @override
  bool shouldRebuildSemantics(CustomPainter oldDelegate) => false;

  @override
  SemanticsBuilderCallback? get semanticsBuilder => null;

  @override
  String toString() => describeIdentity(this);

  @override
  void dispose() {
    fadeoutOpacityAnimation.removeListener(notifyListeners);
    super.dispose();
  }
}
