library interactive_viewer_2;

import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import '../extensions.dart';
import 'scrollbar_painter.dart';

//Copied and modified from the widgets/scrollbar.dart file in the flutter source code
const double _kMinThumbExtent = 18.0;
const double _kScrollbarThickness = 6.0;
const Duration _kScrollbarFadeDuration = Duration(milliseconds: 300);
const Duration _kScrollbarTimeToFade = Duration(milliseconds: 600);

class TransformScrollbarController with ChangeNotifier {
  final PublicScrollbarPainter verticalScrollbar;
  final PublicScrollbarPainter horizontalScrollbar;

  TransformScrollbarController({
    required this.verticalScrollbar,
    required this.horizontalScrollbar,
    TextDirection textDirection = TextDirection.ltr,
  }) {
    verticalScrollbar.addListener(_onScrollbarEvent);
    horizontalScrollbar.addListener(_onScrollbarEvent);
    verticalScrollbar.textDirection = textDirection;
    horizontalScrollbar.textDirection = textDirection;
  }

  void _onScrollbarEvent() {
    notifyListeners();
  }

  @override
  void dispose() {
    verticalScrollbar.removeListener(_onScrollbarEvent);
    horizontalScrollbar.removeListener(_onScrollbarEvent);
    super.dispose();
  }

  /// A changed devicePixelRatio doesn't change anything in thee default implementation.
  /// Therefore, it is always 1.0, without checking the actual devicePixelRatio.
  ///
  /// This method can be overridden to return the actual devicePixelRatio, if needed by a subclass.
  double get devicePixelRatio => 1.0;

  ScrollMetrics getScrollMetricsV(
      Matrix4 transform, Size viewport, Size content) {
    double scale = transform.getScaleOnZAxis();
    Vector3 translation = transform.getTranslation();
    return FixedScrollMetrics(
      minScrollExtent: 0,
      maxScrollExtent: math.max(scale * content.height - viewport.height, 0),
      pixels: -translation.y,
      viewportDimension: viewport.height,
      axisDirection: AxisDirection.down,
      devicePixelRatio: devicePixelRatio,
    );
  }

  ScrollMetrics getScrollMetricsH(
      Matrix4 transform, Size viewport, Size content) {
    double scale = transform.getScaleOnZAxis();
    Vector3 translation = transform.getTranslation();
    return FixedScrollMetrics(
      minScrollExtent: 0,
      maxScrollExtent: math.max(scale * content.width - viewport.width, 0),
      pixels: -translation.x,
      viewportDimension: viewport.width,
      axisDirection: horizontalScrollbar.textDirection == TextDirection.ltr
          ? AxisDirection.right
          : AxisDirection.left,
      devicePixelRatio: devicePixelRatio,
    );
  }

  void update(Matrix4 transform, Size viewport, Size content) {
    verticalScrollbar.update(
      getScrollMetricsV(transform, viewport, content),
      AxisDirection.down,
    );
    horizontalScrollbar.update(
      getScrollMetricsH(transform, viewport, content),
      horizontalScrollbar.textDirection == TextDirection.ltr
          ? AxisDirection.right
          : AxisDirection.left,
    );
  }

  void paint(PaintingContext context, Size viewport, {Offset? origin}) {
    Canvas canvas = context.canvas;
    if (origin != null) {
      canvas.save();
      canvas.translate(origin.dx, origin.dy);
    }
    verticalScrollbar.paint(canvas, viewport);
    horizontalScrollbar.paint(canvas, viewport);
    if (origin != null) {
      canvas.restore();
    }
  }

  void updateAndPaint(
      PaintingContext context, Matrix4 transform, Size viewport, Size content,
      {Offset? origin}) {
    update(transform, viewport, content);
    paint(context, viewport, origin: origin);
  }
}

class SimpleTransformScrollbarController extends TransformScrollbarController {
  SimpleTransformScrollbarController({
    required Color color,
    required this.fadeoutOpacityAnimationVertical,
    required this.fadeoutOpacityAnimationHorizontal,
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
    bool ignorePointer = false,
  }) : super(
          verticalScrollbar: PublicScrollbarPainter(
            color: color,
            fadeoutOpacityAnimation: fadeoutOpacityAnimationVertical,
            trackColor: trackColor,
            trackBorderColor: trackBorderColor,
            textDirection: textDirection,
            thickness: thickness,
            padding: padding,
            mainAxisMargin: mainAxisMargin,
            crossAxisMargin: crossAxisMargin,
            radius: radius,
            trackRadius: trackRadius,
            shape: shape,
            minLength: minLength,
            minOverscrollLength: minOverscrollLength,
            scrollbarOrientation: ScrollbarOrientation.right,
            ignorePointer: ignorePointer,
          ),
          horizontalScrollbar: PublicScrollbarPainter(
            color: color,
            fadeoutOpacityAnimation: fadeoutOpacityAnimationHorizontal,
            trackColor: trackColor,
            trackBorderColor: trackBorderColor,
            textDirection: textDirection,
            thickness: thickness,
            padding: padding,
            mainAxisMargin: mainAxisMargin,
            crossAxisMargin: crossAxisMargin,
            radius: radius,
            trackRadius: trackRadius,
            shape: shape,
            minLength: minLength,
            minOverscrollLength: minOverscrollLength,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            ignorePointer: ignorePointer,
          ),
          textDirection: textDirection ?? TextDirection.ltr,
        );

  final Animation<double> fadeoutOpacityAnimationVertical;
  final Animation<double> fadeoutOpacityAnimationHorizontal;

  @override
  void dispose() {
    verticalScrollbar.dispose();
    horizontalScrollbar.dispose();
    super.dispose();
  }
}

class ExtendedTransformScrollbarController
    extends SimpleTransformScrollbarController {
  ExtendedTransformScrollbarController({
    required this.fadeoutAnimationControllerVertical,
    required this.fadeoutAnimationControllerHorizontal,
    required this.controlInterface,
    this.scrollPhysics,
    this.thumbVisibility,
    this.shape,
    this.radius,
    this.thickness,
    this.thumbColor,
    this.minThumbLength = _kMinThumbExtent,
    this.minOverscrollLength,
    bool? trackVisibility,
    this.trackRadius,
    this.trackColor,
    this.trackBorderColor,
    this.fadeDuration = _kScrollbarFadeDuration,
    this.timeToFade = _kScrollbarTimeToFade,
    this.pressDuration = Duration.zero,
    this.interactive,
    this.mainAxisMargin = 0.0,
    this.crossAxisMargin = 0.0,
    this.padding,
  })  : assert(
          !(thumbVisibility == false && (trackVisibility ?? false)),
          'A scrollbar track cannot be drawn without a scrollbar thumb.',
        ),
        assert(minThumbLength >= 0),
        assert(minOverscrollLength == null ||
            minOverscrollLength <= minThumbLength),
        assert(minOverscrollLength == null || minOverscrollLength >= 0),
        assert(radius == null || shape == null),
        trackVisibilityV = trackVisibility,
        trackVisibilityH = trackVisibility,
        super(
          fadeoutOpacityAnimationHorizontal: CurvedAnimation(
            parent: fadeoutAnimationControllerHorizontal,
            curve: Curves.fastOutSlowIn,
          ),
          fadeoutOpacityAnimationVertical: CurvedAnimation(
            parent: fadeoutAnimationControllerVertical,
            curve: Curves.fastOutSlowIn,
          ),
          color: thumbColor ?? const Color(0x66BCBCBC),
          thickness: thickness ?? _kScrollbarThickness,
          radius: radius,
          trackRadius: trackRadius,
          mainAxisMargin: mainAxisMargin,
          shape: shape,
          crossAxisMargin: crossAxisMargin,
          minLength: minThumbLength,
          minOverscrollLength: minOverscrollLength ?? minThumbLength,
        );

  /// {@template flutter.widgets.Scrollbar.thumbVisibility}
  /// Indicates that the scrollbar thumb should be visible, even when a scroll
  /// is not underway.
  ///
  /// When false, the scrollbar will be shown during scrolling
  /// and will fade out otherwise.
  ///
  /// When true, the scrollbar will always be visible and never fade out. This
  /// requires that the Scrollbar can access the [ScrollController] of the
  /// associated Scrollable widget. This can either be the provided [controller],
  /// or the [PrimaryScrollController] of the current context.
  ///
  ///   * When providing a controller, the same ScrollController must also be
  ///     provided to the associated Scrollable widget.
  ///   * The [PrimaryScrollController] is used by default for a [ScrollView]
  ///     that has not been provided a [ScrollController] and that has a
  ///     [ScrollView.scrollDirection] of [Axis.vertical]. This automatic
  ///     behavior does not apply to those with [Axis.horizontal]. To explicitly
  ///     use the PrimaryScrollController, set [ScrollView.primary] to true.
  ///
  /// Defaults to false when null.
  ///
  /// {@tool snippet}
  ///
  /// ```dart
  /// // (e.g. in a stateful widget)
  ///
  /// final ScrollController controllerOne = ScrollController();
  /// final ScrollController controllerTwo = ScrollController();
  ///
  /// @override
  /// Widget build(BuildContext context) {
  /// return Column(
  ///   children: <Widget>[
  ///     SizedBox(
  ///        height: 200,
  ///        child: Scrollbar(
  ///          thumbVisibility: true,
  ///          controller: controllerOne,
  ///          child: ListView.builder(
  ///            controller: controllerOne,
  ///            itemCount: 120,
  ///            itemBuilder: (1, int index) {
  ///              return Text('item $index');
  ///            },
  ///          ),
  ///        ),
  ///      ),
  ///      SizedBox(
  ///        height: 200,
  ///        child: CupertinoScrollbar(
  ///          thumbVisibility: true,
  ///          controller: controllerTwo,
  ///          child: SingleChildScrollView(
  ///            controller: controllerTwo,
  ///            child: const SizedBox(
  ///              height: 2000,
  ///              width: 500,
  ///              child: Placeholder(),
  ///            ),
  ///          ),
  ///        ),
  ///      ),
  ///    ],
  ///   );
  /// }
  /// ```
  /// {@end-tool}
  ///
  /// See also:
  ///
  ///   * [RawScrollbarState.showScrollbar], an overridable getter which uses
  ///     this value to override the default behavior.
  ///   * [ScrollView.primary], which indicates whether the ScrollView is the primary
  ///     scroll view associated with the parent [PrimaryScrollController].
  ///   * [PrimaryScrollController], which associates a [ScrollController] with
  ///     a subtree.
  /// {@endtemplate}
  ///
  /// Subclass [Scrollbar] can hide and show the scrollbar thumb in response to
  /// [MaterialState]s by using [ScrollbarThemeData.thumbVisibility].
  final bool? thumbVisibility;

  /// The [OutlinedBorder] of the scrollbar's thumb.
  ///
  /// Only one of [radius] and [shape] may be specified. For a rounded rectangle,
  /// it's simplest to just specify [radius]. By default, the scrollbar thumb's
  /// shape is a simple rectangle.
  ///
  /// If [shape] is specified, the thumb will take the shape of the passed
  /// [OutlinedBorder] and fill itself with [thumbColor] (or grey if it
  /// is unspecified).
  ///
  /// {@tool dartpad}
  /// This is an example of using a [StadiumBorder] for drawing the [shape] of the
  /// thumb in a [RawScrollbar].
  ///
  /// ** See code in examples/api/lib/widgets/scrollbar/raw_scrollbar.shape.0.dart **
  /// {@end-tool}
  final OutlinedBorder? shape;

  /// The [Radius] of the scrollbar thumb's rounded rectangle corners.
  ///
  /// Scrollbar will be rectangular if [radius] is null, which is the default
  /// behavior.
  final Radius? radius;

  /// The thickness of the scrollbar in the cross axis of the scrollable.
  ///
  /// If null, will default to 6.0 pixels.
  final double? thickness;

  /// The color of the scrollbar thumb.
  ///
  /// If null, defaults to Color(0x66BCBCBC).
  final Color? thumbColor;

  /// The preferred smallest size the scrollbar thumb can shrink to when the total
  /// scrollable extent is large, the current visible viewport is small, and the
  /// viewport is not overscrolled.
  ///
  /// The size of the scrollbar's thumb may shrink to a smaller size than [minThumbLength]
  /// to fit in the available paint area (e.g., when [minThumbLength] is greater
  /// than [ScrollMetrics.viewportDimension] and [mainAxisMargin] combined).
  ///
  /// Mustn't be null and the value has to be greater or equal to
  /// [minOverscrollLength], which in turn is >= 0. Defaults to 18.0.
  final double minThumbLength;

  /// The preferred smallest size the scrollbar thumb can shrink to when viewport is
  /// overscrolled.
  ///
  /// When overscrolling, the size of the scrollbar's thumb may shrink to a smaller size
  /// than [minOverscrollLength] to fit in the available paint area (e.g., when
  /// [minOverscrollLength] is greater than [ScrollMetrics.viewportDimension] and
  /// [mainAxisMargin] combined).
  ///
  /// Overscrolling can be made possible by setting the `physics` property
  /// of the `child` Widget to a `BouncingScrollPhysics`, which is a special
  /// `ScrollPhysics` that allows overscrolling.
  ///
  /// The value is less than or equal to [minThumbLength] and greater than or equal to 0.
  /// When null, it will default to the value of [minThumbLength].
  final double? minOverscrollLength;

  /// {@template flutter.widgets.Scrollbar.trackVisibility}
  /// Indicates that the scrollbar track should be visible.
  ///
  /// When true, the scrollbar track will always be visible so long as the thumb
  /// is visible. If the scrollbar thumb is not visible, the track will not be
  /// visible either.
  ///
  /// Defaults to false when null.
  /// {@endtemplate}
  ///
  /// Subclass [Scrollbar] can hide and show the scrollbar thumb in response to
  /// [MaterialState]s by using [ScrollbarThemeData.trackVisibility].
  final bool? trackVisibilityV;

  final bool? trackVisibilityH;

  /// The [Radius] of the scrollbar track's rounded rectangle corners.
  ///
  /// Scrollbar's track will be rectangular if [trackRadius] is null, which is
  /// the default behavior.
  final Radius? trackRadius;

  /// The color of the scrollbar track.
  ///
  /// The scrollbar track will only be visible when [trackVisibility] and
  /// [thumbVisibility] are true.
  ///
  /// If null, defaults to Color(0x08000000).
  final Color? trackColor;

  /// The color of the scrollbar track's border.
  ///
  /// The scrollbar track will only be visible when [trackVisibility] and
  /// [thumbVisibility] are true.
  ///
  /// If null, defaults to Color(0x1a000000).
  final Color? trackBorderColor;

  /// The [Duration] of the fade animation.
  ///
  /// Defaults to a [Duration] of 300 milliseconds.
  final Duration fadeDuration;

  /// The [Duration] of time until the fade animation begins.
  ///
  /// Defaults to a [Duration] of 600 milliseconds.
  final Duration timeToFade;

  /// The [Duration] of time that a LongPress will trigger the drag gesture of
  /// the scrollbar thumb.
  ///
  /// Defaults to [Duration.zero].
  final Duration pressDuration;

  /// {@template flutter.widgets.Scrollbar.interactive}
  /// Whether the Scrollbar should be interactive and respond to dragging on the
  /// thumb, or tapping in the track area.
  ///
  /// Does not apply to the [CupertinoScrollbar], which is always interactive to
  /// match native behavior. On Android, the scrollbar is not interactive by
  /// default.
  ///
  /// When false, the scrollbar will not respond to gesture or hover events,
  /// and will allow to click through it.
  ///
  /// Defaults to true when null, unless on Android, which will default to false
  /// when null.
  ///
  /// See also:
  ///
  ///   * [RawScrollbarState.enableGestures], an overridable getter which uses
  ///     this value to override the default behavior.
  /// {@endtemplate}
  final bool? interactive;

  /// Distance from the scrollbar thumb's start or end to the nearest edge of
  /// the viewport in logical pixels. It affects the amount of available
  /// paint area.
  ///
  /// The scrollbar track consumes this space.
  ///
  /// Mustn't be null and defaults to 0.
  final double mainAxisMargin;

  /// Distance from the scrollbar thumb's side to the nearest cross axis edge
  /// in logical pixels.
  ///
  /// The scrollbar track consumes this space.
  ///
  /// Defaults to zero.
  final double crossAxisMargin;

  /// The insets by which the scrollbar thumb and track should be padded.
  ///
  /// When null, the inherited [MediaQueryData.padding] is used.
  ///
  /// Defaults to null.
  final EdgeInsets? padding;

  /// Provide a way to update your scrollbar if the thumb is dragged.
  final TransformScrollbarWidgetInterface controlInterface;

  /// The [ScrollPhysics] that will determine how the scrollbar behaves.
  ScrollPhysics? scrollPhysics;

  @protected
  ScrollPhysics get physics {
    return scrollPhysics ??
        ScrollConfiguration.of(context).getScrollPhysics(context);
  }

  final AnimationController fadeoutAnimationControllerVertical;
  final AnimationController fadeoutAnimationControllerHorizontal;

  Offset? _startDragScrollbarAxisOffsetV;
  Offset? _startDragScrollbarAxisOffsetH;
  Offset? _lastDragUpdateOffsetV;
  Offset? _lastDragUpdateOffsetH;
  double? _startDragThumbOffsetV;
  double? _startDragThumbOffsetH;
  Timer? _fadeoutTimerV;
  Timer? _fadeoutTimerH;
  bool _hoverIsActiveV = false;
  bool _hoverIsActiveH = false;
  bool _thumbDraggingV = false;
  bool _thumbDraggingH = false;

  bool get shouldAllowMouseScroll =>
      (!_thumbDraggingV || !_thumbDraggingH) || kIsWeb;

  BuildContext get context => controlInterface.getContext();

  /// Overridable getter to indicate that the scrollbar should be visible, even
  /// when a scroll is not underway.
  ///
  /// Subclasses can override this getter to make its value depend on an inherited
  /// theme.
  ///
  /// Defaults to false when [RawScrollbar.thumbVisibility] is null.
  @protected
  bool get showScrollbarV => thumbVisibility ?? false;

  bool get showScrollbarH => thumbVisibility ?? false;

  bool get _showTrackV => showScrollbarV && (trackVisibilityV ?? false);

  bool get _showTrackH => showScrollbarH && (trackVisibilityH ?? false);

  /// Overridable getter to indicate is gestures should be enabled on the
  /// scrollbar.
  ///
  /// When false, the scrollbar will not respond to gesture or hover events,
  /// and will allow to click through it.
  ///
  /// Subclasses can override this getter to make its value depend on an inherited
  /// theme.
  ///
  /// Defaults to true when [RawScrollbar.interactive] is null.
  ///
  /// See also:
  ///
  ///   * [RawScrollbar.interactive], which overrides the default behavior.
  bool get enableGestures => interactive ?? true;

  /// This method is responsible for configuring the [horizontalScrollbar] and [verticalScrollbar]
  /// according to the [widget]'s properties and any inherited widgets the
  /// painter depends on, like [Directionality] and [MediaQuery].
  ///
  /// Subclasses can override to configure the [horizontalScrollbar] and [verticalScrollbar].
  ///
  /// See also:
  ///  * [updateScrollbarPainter], which is called by this methods default implementation for each [scrollbarPainter].
  void updateScrollbarPainters() {
    updateScrollbarPainter(true);
    updateScrollbarPainter(false);
  }

  /// This method is responsible for configuring one [scrollbarPainter] according
  /// to the [widget]'s properties and any inherited widgets the painter depends
  /// on, like [Directionality] and [MediaQuery].
  ///
  /// This method is called by [updateScrollbarPainters] for each [scrollbarPainter].
  /// Subclasses can override to configure the [scrollbarPainter].
  @protected
  void updateScrollbarPainter(bool vertical) {
    PublicScrollbarPainter scrollbarPainter =
        vertical ? verticalScrollbar : horizontalScrollbar;
    scrollbarPainter
      ..color = thumbColor ?? const Color(0x66BCBCBC)
      ..trackRadius = trackRadius
      ..trackColor = (vertical ? _showTrackV : _showTrackH)
          ? trackColor ?? const Color(0x08000000)
          : const Color(0x00000000)
      ..trackBorderColor = (vertical ? _showTrackV : _showTrackH)
          ? trackBorderColor ?? const Color(0x1a000000)
          : const Color(0x00000000)
      ..textDirection = Directionality.of(context)
      ..thickness = thickness ?? _kScrollbarThickness
      ..radius = radius
      ..padding = padding ?? MediaQuery.paddingOf(context)
      ..mainAxisMargin = mainAxisMargin
      ..shape = shape
      ..crossAxisMargin = crossAxisMargin
      ..minLength = minThumbLength
      ..minOverscrollLength = minOverscrollLength ?? minThumbLength
      ..ignorePointer = !enableGestures;
  }

  void onDidUpdateWidget() {
    if (thumbVisibility != thumbVisibility) {
      if (thumbVisibility ?? false) {
        _fadeoutTimerV?.cancel();
        _fadeoutTimerH?.cancel();
        fadeoutAnimationControllerVertical.animateTo(1.0);
        fadeoutAnimationControllerHorizontal.animateTo(1.0);
      } else {
        fadeoutAnimationControllerVertical.reverse();
        fadeoutAnimationControllerHorizontal.reverse();
      }
    }
  }

  void updateVerticalScrollPosition(Offset updatedOffset) {
    Matrix4 transform = controlInterface.getTransform();
    _updateScrollPositionP(
      updatedOffset,
      _startDragScrollbarAxisOffsetV,
      _lastDragUpdateOffsetV,
      _startDragThumbOffsetV,
      verticalScrollbar,
      AxisDirection.down,
      transform.getTranslation().y,
      getScrollMetricsV(transform, controlInterface.getViewport(),
          controlInterface.getContent()),
      controlInterface.jumpVertical,
    );
  }

  void updateHorizontalScrollPosition(Offset updatedOffset) {
    Matrix4 transform = controlInterface.getTransform();
    _updateScrollPositionP(
      updatedOffset,
      _startDragScrollbarAxisOffsetH,
      _lastDragUpdateOffsetH,
      _startDragThumbOffsetH,
      horizontalScrollbar,
      horizontalScrollbar.textDirection == TextDirection.ltr
          ? AxisDirection.right
          : AxisDirection.left,
      transform.getTranslation().x,
      getScrollMetricsH(transform, controlInterface.getViewport(),
          controlInterface.getContent()),
      controlInterface.jumpHorizontal,
    );
  }

  void _updateScrollPositionP(
      Offset updatedOffset,
      Offset? startDragScrollbarAxisOffset,
      Offset? lastDragUpdateOffset,
      double? startDragThumbOffset,
      PublicScrollbarPainter scrollbarPainter,
      AxisDirection axisDirection,
      double translation,
      ScrollMetrics scrollMetrics,
      Function(double) jump) {
    assert(startDragScrollbarAxisOffset != null);
    assert(lastDragUpdateOffset != null);
    assert(startDragThumbOffset != null);

    //final ScrollPosition position = _cachedController!.position;
    late double primaryDeltaFromDragStart;
    late double primaryDeltaFromLastDragUpdate;
    switch (axisDirection) {
      case AxisDirection.up:
        primaryDeltaFromDragStart =
            startDragScrollbarAxisOffset!.dy - updatedOffset.dy;
        primaryDeltaFromLastDragUpdate =
            lastDragUpdateOffset!.dy - updatedOffset.dy;
        break;
      case AxisDirection.right:
        primaryDeltaFromDragStart =
            updatedOffset.dx - startDragScrollbarAxisOffset!.dx;
        primaryDeltaFromLastDragUpdate =
            updatedOffset.dx - lastDragUpdateOffset!.dx;
        break;
      case AxisDirection.down:
        primaryDeltaFromDragStart =
            updatedOffset.dy - startDragScrollbarAxisOffset!.dy;
        primaryDeltaFromLastDragUpdate =
            updatedOffset.dy - lastDragUpdateOffset!.dy;
        break;
      case AxisDirection.left:
        primaryDeltaFromDragStart =
            startDragScrollbarAxisOffset!.dx - updatedOffset.dx;
        primaryDeltaFromLastDragUpdate =
            lastDragUpdateOffset!.dx - updatedOffset.dx;
        break;
    }
    //final double scrollableExtent = scrollMetrics.maxScrollExtent-scrollMetrics.minScrollExtent;
    //final double viewport = scrollMetrics.viewportDimension;

    //jump(-scrollableExtent * primaryDeltaFromLastDragUpdate / viewport);
    //jump(scrollbarPainter.getTrackToScroll(-primaryDeltaFromLastDragUpdate));
    double scrollOffsetGlobal = scrollbarPainter
        .getTrackToScroll(primaryDeltaFromDragStart + startDragThumbOffset!);
    if (primaryDeltaFromDragStart > 0 &&
            scrollOffsetGlobal < scrollMetrics.pixels ||
        primaryDeltaFromDragStart < 0 &&
            scrollOffsetGlobal > scrollMetrics.pixels) {
      // Adjust the position value if the scrolling direction conflicts with
      // the dragging direction due to scroll metrics shrink.
      scrollOffsetGlobal = scrollMetrics.pixels +
          scrollbarPainter.getTrackToScroll(primaryDeltaFromLastDragUpdate);
    }
    double delta = scrollOffsetGlobal - scrollMetrics.pixels;
    jump(-delta);
  }

  void _maybeStartFadeoutTimer({bool vertical = true, bool horizontal = true}) {
    if (!showScrollbarV && vertical && !_thumbDraggingV) {
      _fadeoutTimerV?.cancel();
      _fadeoutTimerV = Timer(timeToFade, () {
        fadeoutAnimationControllerVertical.reverse();
        _fadeoutTimerV = null;
      });
    }
    if (!showScrollbarH && horizontal && !_thumbDraggingH) {
      _fadeoutTimerH?.cancel();
      _fadeoutTimerH = Timer(timeToFade, () {
        fadeoutAnimationControllerHorizontal.reverse();
        _fadeoutTimerH = null;
      });
    }
  }

  /// Handler called when a press on the vertical scrollbar thumb has been recognized.
  ///
  /// Cancels the [Timer] associated with the fade animation of the scrollbar.
  @mustCallSuper
  void handleThumbPressVertical() {
    _fadeoutTimerV?.cancel();
  }

  void handleThumbPressHorizontal() {
    _fadeoutTimerH?.cancel();
  }

  /// Handler called when a long press gesture has started on the vertical scrollbar.
  ///
  /// Begins the fade out animation and initializes dragging the scrollbar thumb.
  @protected
  @mustCallSuper
  void handleThumbPressStartVertical(Offset position) {
    Offset localPosition = position.toLocal(context);
    _fadeoutTimerV?.cancel();
    fadeoutAnimationControllerVertical.forward();
    _startDragScrollbarAxisOffsetV = localPosition;
    _lastDragUpdateOffsetV = localPosition;
    _startDragThumbOffsetV = verticalScrollbar.getThumbScrollOffset();
    _thumbDraggingV = true;
  }

  /// Handler called when a long press gesture has started on the horizontal scrollbar.
  ///
  /// Begins the fade out animation and initializes dragging the scrollbar thumb.
  @protected
  @mustCallSuper
  void handleThumbPressStartHorizontal(Offset position) {
    Offset localPosition = position.toLocal(context);
    _fadeoutTimerH?.cancel();
    fadeoutAnimationControllerHorizontal.forward();
    _startDragScrollbarAxisOffsetH = localPosition;
    _lastDragUpdateOffsetH = localPosition;
    _startDragThumbOffsetH = horizontalScrollbar.getThumbScrollOffset();
    _thumbDraggingH = true;
  }

  /// Handler called when a currently active long press gesture moves.
  ///
  /// Updates the position of the child scrollable.
  @protected
  @mustCallSuper
  void handleThumbPressUpdateVertical(Offset position) {
    Offset localPosition = position.toLocal(context);
    if (_lastDragUpdateOffsetV == localPosition) {
      return;
    }
    if (!physics.shouldAcceptUserOffset(getScrollMetricsV(
        controlInterface.getTransform(),
        controlInterface.getViewport(),
        controlInterface.getContent()))) {
      return;
    }
    updateVerticalScrollPosition(localPosition);
    _lastDragUpdateOffsetV = localPosition;
  }

  /// Handler called when a currently active long press gesture moves.
  ///
  /// Updates the position of the child scrollable.
  @protected
  @mustCallSuper
  void handleThumbPressUpdateHorizontal(Offset position) {
    Offset localPosition = position.toLocal(context);
    if (_lastDragUpdateOffsetH == localPosition) {
      return;
    }
    if (!physics.shouldAcceptUserOffset(getScrollMetricsH(
        controlInterface.getTransform(),
        controlInterface.getViewport(),
        controlInterface.getContent()))) {
      return;
    }
    updateHorizontalScrollPosition(localPosition);
    _lastDragUpdateOffsetH = localPosition;
  }

  /// Handler called when a long press on vertical scrollbar has ended.
  @protected
  @mustCallSuper
  void handleThumbPressEndVertical(Offset position, Velocity velocity) {
    _thumbDraggingV = false;
    _maybeStartFadeoutTimer(horizontal: false);
    _startDragScrollbarAxisOffsetV = null;
    _lastDragUpdateOffsetV = null;
    _startDragThumbOffsetV = null;
  }

  /// Handler called when a long press on horizontal scrollbar has ended.
  @protected
  @mustCallSuper
  void handleThumbPressEndHorizontal(Offset position, Velocity velocity) {
    _thumbDraggingH = false;
    _maybeStartFadeoutTimer(vertical: false);
    _startDragScrollbarAxisOffsetH = null;
    _lastDragUpdateOffsetH = null;
    _startDragThumbOffsetH = null;
  }

  void handleTrackTapDownVertical(TapDownDetails details) {
    // The Scrollbar should page towards the position of the tap on the track.
    Matrix4 transform = controlInterface.getTransform();
    final ScrollMetrics metrics = getScrollMetricsV(transform,
        controlInterface.getViewport(), controlInterface.getContent());
    if (!physics.shouldAcceptUserOffset(metrics)) {
      return;
    }
    late final double delta;
    if (details.localPosition.dy < verticalScrollbar.thumbOffset) {
      delta = -metrics.viewportDimension * 0.8;
    } else {
      delta = metrics.viewportDimension * 0.8;
    }
    controlInterface.animateVertical(
      delta,
      const Duration(milliseconds: 100),
      Curves.easeInOut,
    );
  }

  void handleTrackTapDownHorizontal(TapDownDetails details) {
    // The Scrollbar should page towards the position of the tap on the track.

    Matrix4 transform = controlInterface.getTransform();
    final ScrollMetrics metrics = getScrollMetricsH(transform,
        controlInterface.getViewport(), controlInterface.getContent());
    if (!physics.shouldAcceptUserOffset(metrics)) {
      return;
    }
    late final double delta;
    if (details.localPosition.dx < horizontalScrollbar.thumbOffset) {
      delta = -metrics.viewportDimension * 0.8;
    } else {
      delta = metrics.viewportDimension * 0.8;
    }
    controlInterface.animateHorizontal(
      delta,
      const Duration(milliseconds: 100),
      Curves.easeInOut,
    );
  }

  void onScrollStart() {
    onScrollStartVertical();
    onScrollStartHorizontal();
  }

  void onScrollEnd() {
    onScrollEndVertical();
    onScrollEndHorizontal();
  }

  void onScrollStartVertical() {
    if (fadeoutAnimationControllerVertical.status != AnimationStatus.forward &&
        fadeoutAnimationControllerVertical.status !=
            AnimationStatus.completed) {
      fadeoutAnimationControllerVertical.forward();
    }
    _fadeoutTimerV?.cancel();
  }

  void onScrollStartHorizontal() {
    if (fadeoutAnimationControllerHorizontal.status !=
            AnimationStatus.forward &&
        fadeoutAnimationControllerHorizontal.status !=
            AnimationStatus.completed) {
      fadeoutAnimationControllerHorizontal.forward();
    }
    _fadeoutTimerH?.cancel();
  }

  void onScrollEndVertical() {
    if (_startDragScrollbarAxisOffsetV == null) {
      _maybeStartFadeoutTimer(horizontal: false);
    }
  }

  void onScrollEndHorizontal() {
    if (_startDragScrollbarAxisOffsetH == null) {
      _maybeStartFadeoutTimer(vertical: false);
    }
  }

  /// Returns true if the provided [Offset] is located over the track of the
  /// vertical Scrollbar.
  @protected
  bool isPointerOverTrackV(Offset position, PointerDeviceKind kind) {
    Offset localPosition = position.toLocal(context);
    return verticalScrollbar.hitTestInteractive(localPosition, kind) &&
        !verticalScrollbar.hitTestOnlyThumbInteractive(localPosition, kind);
  }

  /// Returns true if the provided [Offset] is located over the track of the
  /// horizontal Scrollbar.
  @protected
  bool isPointerOverTrackH(Offset position, PointerDeviceKind kind) {
    Offset localPosition = position.toLocal(context);
    return horizontalScrollbar.hitTestInteractive(localPosition, kind) &&
        !horizontalScrollbar.hitTestOnlyThumbInteractive(localPosition, kind);
  }

  /// Returns true if the provided [Offset] is located over the thumb of the
  /// vertical Scrollbar.
  @protected
  bool isPointerOverThumbV(Offset position, PointerDeviceKind kind) {
    Offset localPosition = position.toLocal(context);
    return verticalScrollbar.hitTestOnlyThumbInteractive(localPosition, kind);
  }

  /// Returns true if the provided [Offset] is located over the thumb of the
  /// horizontal Scrollbar.
  @protected
  bool isPointerOverThumbH(Offset position, PointerDeviceKind kind) {
    Offset localPosition = position.toLocal(context);
    return horizontalScrollbar.hitTestOnlyThumbInteractive(localPosition, kind);
  }

  /// Returns true if the provided [Offset] is located over the track or thumb
  /// of the vertical Scrollbar.
  ///
  /// The hit test area for mouse hovering over the scrollbar is larger than
  /// regular hit testing. This is to make it easier to interact with the
  /// scrollbar and present it to the mouse for interaction based on proximity.
  /// When `forHover` is true, the larger hit test area will be used.
  @protected
  bool isPointerOverScrollbarV(Offset position, PointerDeviceKind kind) {
    //Offset localPosition = position.toLocal(context);
    return verticalScrollbar.hitTestInteractive(position, kind, forHover: true);
  }

  /// Returns true if the provided [Offset] is located over the track or thumb
  /// of the horizontal Scrollbar.
  ///
  /// The hit test area for mouse hovering over the scrollbar is larger than
  /// regular hit testing. This is to make it easier to interact with the
  /// scrollbar and present it to the mouse for interaction based on proximity.
  /// When `forHover` is true, the larger hit test area will be used.
  @protected
  bool isPointerOverScrollbarH(
    Offset position,
    PointerDeviceKind kind,
  ) {
    return horizontalScrollbar.hitTestInteractive(position, kind,
        forHover: true);
  }

  @protected
  @mustCallSuper
  void handleHoverV(PointerHoverEvent event) {
    // Check if the position of the pointer falls over the painted scrollbar
    if (isPointerOverScrollbarV(event.position.toLocal(context), event.kind)) {
      _hoverIsActiveV = true;
      // Bring the scrollbar back into view if it has faded or started to fade
      // away.
      fadeoutAnimationControllerVertical.forward();
      _fadeoutTimerV?.cancel();
    } else if (_hoverIsActiveV) {
      // Pointer is not over painted scrollbar.
      _hoverIsActiveV = false;
      _maybeStartFadeoutTimer(horizontal: false);
    }
  }

  @protected
  @mustCallSuper
  void handleHoverH(PointerHoverEvent event) {
    // Check if the position of the pointer falls over the painted scrollbar
    if (isPointerOverScrollbarH(
      event.position.toLocal(context),
      event.kind,
    )) {
      _hoverIsActiveH = true;
      // Bring the scrollbar back into view if it has faded or started to fade
      // away.
      fadeoutAnimationControllerHorizontal.forward();
      _fadeoutTimerH?.cancel();
    } else if (_hoverIsActiveH) {
      // Pointer is not over painted scrollbar.
      _hoverIsActiveH = false;
      _maybeStartFadeoutTimer(vertical: false);
    }
  }

  void handleHover(PointerHoverEvent event) {
    handleHoverV(event);
    handleHoverH(event);
  }

  /// Initiates the fade out animation.
  @protected
  @mustCallSuper
  void handleHoverExitV(PointerExitEvent event) {
    _hoverIsActiveV = false;
    _maybeStartFadeoutTimer(horizontal: false);
  }

  /// Initiates the fade out animation.
  @protected
  @mustCallSuper
  void handleHoverExitH(PointerExitEvent event) {
    _hoverIsActiveH = false;
    _maybeStartFadeoutTimer(vertical: false);
  }

  @mustCallSuper
  void handleHoverExit(PointerExitEvent event) {
    handleHoverExitV(event);
    handleHoverExitH(event);
  }

  Map<Type, GestureRecognizerFactory> getGesturesVertical(
      BuildContext context) {
    final Map<Type, GestureRecognizerFactory> gestures =
        <Type, GestureRecognizerFactory>{};
    if (!enableGestures) {
      return gestures;
    }

    gestures[_ThumbPressGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<_ThumbPressGestureRecognizer>(
      () => _ThumbPressGestureRecognizer(
        debugOwner: this,
        context: context,
        scrollbarPainter: verticalScrollbar,
        duration: pressDuration,
      ),
      (_ThumbPressGestureRecognizer instance) {
        instance.onLongPress = handleThumbPressVertical;
        instance.onLongPressStart = (LongPressStartDetails details) =>
            handleThumbPressStartVertical(details.globalPosition);
        instance.onLongPressMoveUpdate = (LongPressMoveUpdateDetails details) =>
            handleThumbPressUpdateVertical(details.globalPosition);
        instance.onLongPressEnd = (LongPressEndDetails details) =>
            handleThumbPressEndVertical(
                details.globalPosition, details.velocity);
      },
    );

    gestures[_TrackTapGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<_TrackTapGestureRecognizer>(
      () => _TrackTapGestureRecognizer(
        debugOwner: this,
        context: context,
        scrollbarPainter: verticalScrollbar,
      ),
      (_TrackTapGestureRecognizer instance) {
        instance.onTapDown = handleTrackTapDownVertical;
      },
    );

    return gestures;
  }

  Map<Type, GestureRecognizerFactory> getGesturesHorizontal(
      BuildContext context) {
    final Map<Type, GestureRecognizerFactory> gestures =
        <Type, GestureRecognizerFactory>{};
    if (!enableGestures) {
      return gestures;
    }

    gestures[_ThumbPressGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<_ThumbPressGestureRecognizer>(
      () => _ThumbPressGestureRecognizer(
        debugOwner: this,
        context: context,
        scrollbarPainter: horizontalScrollbar,
        duration: pressDuration,
      ),
      (_ThumbPressGestureRecognizer instance) {
        instance.onLongPress = handleThumbPressHorizontal;
        instance.onLongPressStart = (LongPressStartDetails details) =>
            handleThumbPressStartHorizontal(details.globalPosition);
        instance.onLongPressMoveUpdate = (LongPressMoveUpdateDetails details) =>
            handleThumbPressUpdateHorizontal(details.globalPosition);
        instance.onLongPressEnd = (LongPressEndDetails details) =>
            handleThumbPressEndHorizontal(
                details.globalPosition, details.velocity);
      },
    );

    gestures[_TrackTapGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<_TrackTapGestureRecognizer>(
      () => _TrackTapGestureRecognizer(
        debugOwner: this,
        context: context,
        scrollbarPainter: horizontalScrollbar,
      ),
      (_TrackTapGestureRecognizer instance) {
        instance.onTapDown = handleTrackTapDownHorizontal;
      },
    );

    return gestures;
  }
}

abstract class TransformScrollbarWidgetInterface {
  Matrix4 getTransform();

  void jumpVertical(double offset);

  void jumpHorizontal(double offset);

  void animateVertical(double delta, Duration duration, Curve curve);

  void animateHorizontal(double delta, Duration duration, Curve curve);

  Size getViewport();

  Size getContent();

  BuildContext getContext();
}

class CustomTransformScrollbarWidgetInterface
    implements TransformScrollbarWidgetInterface {
  final Matrix4 Function() fgetTransform;

  final void Function(double) fjumpVertical;

  final void Function(double) fjumpHorizontal;

  final void Function(double, Duration, Curve) fanimateVertical;

  final void Function(double, Duration, Curve) fanimateHorizontal;

  final Size Function() fgetViewport;

  final Size Function() fgetContent;

  final BuildContext Function() fcontext;

  CustomTransformScrollbarWidgetInterface({
    required this.fgetTransform,
    required this.fjumpVertical,
    required this.fjumpHorizontal,
    required this.fanimateVertical,
    required this.fanimateHorizontal,
    required this.fgetViewport,
    required this.fgetContent,
    required this.fcontext,
  });

  @override
  Matrix4 getTransform() => fgetTransform();

  @override
  void jumpVertical(double offset) => fjumpVertical(offset);

  @override
  void jumpHorizontal(double offset) => fjumpHorizontal(offset);

  @override
  void animateVertical(double delta, Duration duration, Curve curve) =>
      fanimateVertical(delta, duration, curve);

  @override
  void animateHorizontal(double delta, Duration duration, Curve curve) =>
      fanimateHorizontal(delta, duration, curve);

  @override
  Size getViewport() => fgetViewport();

  @override
  Size getContent() => fgetContent();

  @override
  BuildContext getContext() => fcontext();
}

class _ThumbPressGestureRecognizer extends LongPressGestureRecognizer {
  _ThumbPressGestureRecognizer({
    required Object super.debugOwner,
    required this.scrollbarPainter,
    required this.context,
    required super.duration,
  });

  final BuildContext context;

  final PublicScrollbarPainter scrollbarPainter;

  @override
  bool isPointerAllowed(PointerDownEvent event) {
    if (!_hitTestInteractive(event.position.toLocal(context), event.kind)) {
      return false;
    }
    return super.isPointerAllowed(event);
  }

  bool _hitTestInteractive(Offset offset, PointerDeviceKind kind) {
    return scrollbarPainter.hitTestOnlyThumbInteractive(offset, kind);
  }
}

class _TrackTapGestureRecognizer extends TapGestureRecognizer {
  _TrackTapGestureRecognizer({
    required Object super.debugOwner,
    required this.context,
    required this.scrollbarPainter,
  });

  final BuildContext context;
  final PublicScrollbarPainter scrollbarPainter;

  @override
  bool isPointerAllowed(PointerDownEvent event) {
    if (!_hitTestInteractive(event.position.toLocal(context), event.kind)) {
      return false;
    }
    return super.isPointerAllowed(event);
  }

  bool _hitTestInteractive(Offset offset, PointerDeviceKind kind) {
    return scrollbarPainter.hitTestInteractive(offset, kind) &&
        !scrollbarPainter.hitTestOnlyThumbInteractive(offset, kind);
  }
}

class RawTransformScrollbarController
    extends ExtendedTransformScrollbarController {
  RawTransformScrollbarController({
    required this.vsync,
    required super.controlInterface,
    super.scrollPhysics,
    super.thumbVisibility,
    super.shape,
    super.radius,
    super.thickness,
    super.thumbColor,
    super.minThumbLength,
    super.minOverscrollLength,
    super.trackVisibility,
    super.trackRadius,
    super.trackColor,
    super.trackBorderColor,
    super.fadeDuration,
    super.timeToFade,
    super.pressDuration,
    super.interactive,
    super.mainAxisMargin,
    super.crossAxisMargin,
    super.padding,
  }) : super(
          fadeoutAnimationControllerHorizontal: AnimationController(
            duration: fadeDuration,
            vsync: vsync,
          ),
          fadeoutAnimationControllerVertical: AnimationController(
            duration: fadeDuration,
            vsync: vsync,
          ),
        );

  /// The [TickerProvider] for the Fade in and out animations of the scrollbars.
  final TickerProvider vsync;

  /// Can be overridden to update the scrollbar when the parents widget dependencies change.
  void onDidChangeDependencies() {}

  @override
  void dispose() {
    fadeoutAnimationControllerVertical.dispose();
    fadeoutAnimationControllerHorizontal.dispose();
    super.dispose();
  }
}
