library interactive_viewer_2_src;
// Copied and modified from interactive viewer

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show clampDouble;
import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'scrollbars/auto_platform_scrollbar_controller.dart';
import 'scrollbars/transform_scrollbar_controller.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4, Quad, Vector3;

import 'package:flutter/material.dart';

import 'extensions.dart';

/// A Base Class to build [InteractiveViewer] like widgets, with support for scrollbars, tap to zoom, better viewport sizing, etc.
abstract class BetterInteractiveViewerBase extends StatefulWidget {
  BetterInteractiveViewerBase({
    super.key,
    this.allowNonCoveringScreenZoom = true,
    this.panAxis = PanAxis.free,
    this.maxScale = 2.5,
    this.minScale = 0.2,
    this.interactionEndFrictionCoefficient = _kDrag,
    this.panEnabled = true,
    this.scaleEnabled = true,
    this.showScrollbars = true,
    this.noMouseDragScroll = true,
    this.scaleFactor = kDefaultMouseScrollToScaleFactor,
    this.transformationController,
    this.doubleTapToZoom = true,
  })  : assert(minScale > 0),
        assert(interactionEndFrictionCoefficient > 0),
        assert(minScale.isFinite),
        assert(maxScale > 0),
        assert(!maxScale.isNaN),
        assert(maxScale >= minScale);

  /// When set to [PanAxis.aligned], panning is only allowed in the horizontal
  /// axis or the vertical axis, diagonal panning is not allowed.
  ///
  /// When set to [PanAxis.vertical] or [PanAxis.horizontal] panning is only
  /// allowed in the specified axis. For example, if set to [PanAxis.vertical],
  /// panning will only be allowed in the vertical axis. And if set to [PanAxis.horizontal],
  /// panning will only be allowed in the horizontal axis.
  ///
  /// When set to [PanAxis.free] panning is allowed in all directions.
  ///
  /// Defaults to [PanAxis.free].
  final PanAxis panAxis;

  /// If false, the user will be prevented from panning.
  ///
  /// Defaults to true.
  ///
  /// See also:
  ///
  ///   * [scaleEnabled], which is similar but for scale.
  final bool panEnabled;

  /// If false, the user will be prevented from scaling.
  ///
  /// Defaults to true.
  ///
  /// See also:
  ///
  ///   * [panEnabled], which is similar but for panning.
  final bool scaleEnabled;

  /// Allows the user to zoom by double tapping.
  final bool doubleTapToZoom;

  /// Determines the amount of scale to be performed per pointer scroll.
  ///
  /// Defaults to [kDefaultMouseScrollToScaleFactor].
  ///
  /// Increasing this value above the default causes scaling to feel slower,
  /// while decreasing it causes scaling to feel faster.
  ///
  /// The amount of scale is calculated as the exponential function of the
  /// [PointerScrollEvent.scrollDelta] to [scaleFactor] ratio. In the Flutter
  /// engine, the mousewheel [PointerScrollEvent.scrollDelta] is hardcoded to 20
  /// per scroll, while a trackpad scroll can be any amount.
  ///
  /// Affects only pointer device scrolling, not pinch to zoom.
  final double scaleFactor;

  /// The maximum allowed scale.
  ///
  /// The scale will be clamped between this and [minScale] inclusively.
  ///
  /// Defaults to 2.5.
  ///
  /// Must be greater than zero and greater than [minScale].
  final double maxScale;

  /// The minimum allowed scale.
  ///
  /// The scale will be clamped between this and [maxScale] inclusively.
  ///
  /// Defaults to 0.8.
  ///
  /// Must be a finite number greater than zero and less than [maxScale].
  final double minScale;

  /// Changes the deceleration behavior after a gesture.
  ///
  /// Defaults to 0.0000135.
  ///
  /// Must be a finite number greater than zero.
  final double interactionEndFrictionCoefficient;

  /// A [TransformationController] for the transformation performed on the
  /// child.
  ///
  /// Whenever the child is transformed, the [Matrix4] value is updated and all
  /// listeners are notified. If the value is set, InteractiveDataTable will update
  /// to respect the new value.
  ///
  /// {@tool dartpad}
  /// This example shows how transformationController can be used to animate the
  /// transformation back to its starting position.
  ///
  /// ** See code in examples/api/lib/widgets/interactive_viewer/interactive_viewer.transformation_controller.0.dart **
  /// {@end-tool}
  ///
  /// See also:
  ///
  ///  * [ValueNotifier], the parent class of TransformationController.
  ///  * [TextEditingController] for an example of another similar pattern.
  final TransformationController? transformationController;

  /// Allows the user to zoom out the child so that it is displayed smaller than the viewports width and height.
  final bool allowNonCoveringScreenZoom;

  /// Whether to show scrollbars.
  final bool showScrollbars;

  /// When true, disables drag scrolling with the mouse.
  /// Only mouse wheel zooming, and when enabled scrollbar zooming, is allowed then.
  ///
  /// Defaults to true.
  /// Set to false to match the behavior of [InteractiveViewer].
  final bool noMouseDragScroll;

  // Used as the coefficient of friction in the inertial translation animation.
  // This value was eyeballed to give a feel similar to Google Photos.
  static const double _kDrag = 0.0000135;

  /// Returns the closest point to the given point on the given line segment.
  @visibleForTesting
  static Vector3 getNearestPointOnLine(Vector3 point, Vector3 l1, Vector3 l2) {
    final double lengthSquared = math.pow(l2.x - l1.x, 2.0).toDouble() +
        math.pow(l2.y - l1.y, 2.0).toDouble();

    // In this case, l1 == l2.
    if (lengthSquared == 0) {
      return l1;
    }

    // Calculate how far down the line segment the closest point is and return
    // the point.
    final Vector3 l1P = point - l1;
    final Vector3 l1L2 = l2 - l1;
    final double fraction =
        clampDouble(l1P.dot(l1L2) / lengthSquared, 0.0, 1.0);
    return l1 + l1L2 * fraction;
  }

  /// Given a quad, return its axis aligned bounding box.
  @visibleForTesting
  static Quad getAxisAlignedBoundingBox(Quad quad) {
    final double minX = math.min(
      quad.point0.x,
      math.min(
        quad.point1.x,
        math.min(
          quad.point2.x,
          quad.point3.x,
        ),
      ),
    );
    final double minY = math.min(
      quad.point0.y,
      math.min(
        quad.point1.y,
        math.min(
          quad.point2.y,
          quad.point3.y,
        ),
      ),
    );
    final double maxX = math.max(
      quad.point0.x,
      math.max(
        quad.point1.x,
        math.max(
          quad.point2.x,
          quad.point3.x,
        ),
      ),
    );
    final double maxY = math.max(
      quad.point0.y,
      math.max(
        quad.point1.y,
        math.max(
          quad.point2.y,
          quad.point3.y,
        ),
      ),
    );
    return Quad.points(
      Vector3(minX, minY, 0),
      Vector3(maxX, minY, 0),
      Vector3(maxX, maxY, 0),
      Vector3(minX, maxY, 0),
    );
  }

  /// Returns true iff the point is inside the rectangle given by the Quad,
  /// inclusively.
  /// Algorithm from https://math.stackexchange.com/a/190373.
  @visibleForTesting
  static bool pointIsInside(Vector3 point, Quad quad) {
    final Vector3 aM = point - quad.point0;
    final Vector3 aB = quad.point1 - quad.point0;
    final Vector3 aD = quad.point3 - quad.point0;

    final double aMAB = aM.dot(aB);
    final double aBAB = aB.dot(aB);
    final double aMAD = aM.dot(aD);
    final double aDAD = aD.dot(aD);

    return 0 <= aMAB && aMAB <= aBAB && 0 <= aMAD && aMAD <= aDAD;
  }

  /// Get the point inside (inclusively) the given Quad that is nearest to the
  /// given Vector3.
  @visibleForTesting
  static Vector3 getNearestPointInside(Vector3 point, Quad quad) {
    // If the point is inside the axis aligned bounding box, then it's ok where
    // it is.
    if (pointIsInside(point, quad)) {
      return point;
    }

    // Otherwise, return the nearest point on the quad.
    final List<Vector3> closestPoints = <Vector3>[
      BetterInteractiveViewerBase.getNearestPointOnLine(
          point, quad.point0, quad.point1),
      BetterInteractiveViewerBase.getNearestPointOnLine(
          point, quad.point1, quad.point2),
      BetterInteractiveViewerBase.getNearestPointOnLine(
          point, quad.point2, quad.point3),
      BetterInteractiveViewerBase.getNearestPointOnLine(
          point, quad.point3, quad.point0),
    ];
    double minDistance = double.infinity;
    late Vector3 closestOverall;
    for (final Vector3 closePoint in closestPoints) {
      final double distance = math.sqrt(
        math.pow(point.x - closePoint.x, 2) +
            math.pow(point.y - closePoint.y, 2),
      );
      if (distance < minDistance) {
        minDistance = distance;
        closestOverall = closePoint;
      }
    }
    return closestOverall;
  }

  @override
  BetterInteractiveViewerBaseState<BetterInteractiveViewerBase> createState();
}

/// The state for [BetterInteractiveViewerBase].
abstract class BetterInteractiveViewerBaseState<
        T extends BetterInteractiveViewerBase> extends State<T>
    with TickerProviderStateMixin {
  @protected
  TransformationController? transformationController;

  @protected
  final GlobalKey childKey = GlobalKey();

  @protected
  final GlobalKey parentKey = GlobalKey();
  @protected
  Animation<Offset>? animation;
  @protected
  Animation<double>? scaleAnimation;
  @protected
  late Offset scaleAnimationFocalPoint;
  @protected
  late AnimationController controller;
  @protected
  late AnimationController scaleController;
  @protected
  Axis? currentAxis; // Used with panAxis.
  @protected
  Offset? referenceFocalPoint; // Point where the current gesture began.
  @protected
  double? scaleStart; // Scale value at start of scaling gesture.
  @protected
  double? rotationStart = 0.0; // Rotation at start of rotation gesture.
  @protected
  double currentRotation = 0.0; // Rotation of _transformationController.value.
  @protected
  GestureType? gestureType;

  @protected
  RawTransformScrollbarController? scrollbarController;

  /// Set this value if the child has a different size than returned by its render box
  @protected
  Size? realChildSize;

  @protected
  bool inNonCoveringZoomHorizontal = false;

  @protected
  bool inNonCoveringZoomVertical = false;

  ///Realign the transformation controllers value after a nonCoveringZoom (child is smaller than viewport) to make sure it can be displayed correctly
  @protected
  void afterZoom() {
    Matrix4 oldValue = transformationController!.value.clone();
    Vector3 oldTranslation = oldValue.getTranslation();
    bool set = false;
    if (inNonCoveringZoomHorizontal) {
      oldTranslation.x = 0;
      set = true;
    }
    if (inNonCoveringZoomVertical) {
      oldTranslation.y = 0;
      set = true;
    }
    if (set) {
      oldValue.setTranslation(oldTranslation);
      transformationController!.value = oldValue;
    }
  }

  /// Cal this method after resize
  @protected
  void afterResize({bool forceUpdate = true}) {
    Matrix4 transform = transformationController!.value;
    Vector3 translation = transform.getTranslation();
    Rect boundaryRect = childBoundaryRect;
    Rect viewport = widgetViewport;

    double scale = transform.getScaleOnZAxis();

    double realWidth = boundaryRect.width * scale;
    double realHeight = boundaryRect.height * scale;

    double leftPositionX = translation.x;
    double topPositionY = translation.y;
    double rightPositionX = leftPositionX + realWidth;
    double bottomPositionY = topPositionY + realHeight;

    bool changed = false;
    if (realWidth > viewport.width) {
      if (leftPositionX < 0 && rightPositionX < viewport.width) {
        translation.x = viewport.width - realWidth;
        changed = true;
      }
    }

    if (realWidth < viewport.width && translation.x != 0.0) {
      translation.x = 0;
      changed = true;
    }

    if (realHeight > viewport.height) {
      if (topPositionY < 0 && bottomPositionY < viewport.height) {
        translation.y = viewport.height - realHeight;
        changed = true;
      }
    }

    if (realHeight < viewport.height && translation.y != 0.0) {
      translation.y = 0;
      changed = true;
    }

    if (changed) {
      transform = transform.clone()..setTranslation(translation);
      transformationController!.value = transform;
    } else if (forceUpdate) {
      updateTransform();
    }
  }

  /// The actual transform you should use for rendering
  @protected
  Matrix4 get transformForRender {
    if (!widget.allowNonCoveringScreenZoom || childKey.currentContext == null) {
      inNonCoveringZoomHorizontal = false;
      inNonCoveringZoomVertical = false;
      return transformationController!.value;
    }
    Matrix4 transform = transformationController!.value;
    Rect boundaryRect = childBoundaryRect;
    Rect viewport = widgetViewport;
    double scale = transform.getScaleOnZAxis();
    inNonCoveringZoomHorizontal = boundaryRect.width * scale < viewport.width;
    inNonCoveringZoomVertical = boundaryRect.height * scale < viewport.height;
    if (inNonCoveringZoomHorizontal || inNonCoveringZoomVertical) {
      transform = transform.clone(); //dont change the transformation controller
      transform.scale(1 / scale);
      Vector3 translation = transform.getTranslation();
      if (inNonCoveringZoomHorizontal) {
        translation.x = getNonCoveringZoomHorizontalTranslation(scale);
      }
      if (inNonCoveringZoomVertical) {
        translation.y = getNonCoveringZoomVerticalTranslation(scale);
      }
      transform.setTranslation(translation);
      transform.scale(scale);
    }
    return transform;
  }

  ///How to align the child on non covering zoom for Horizontal axis
  ///
  /// Used by [getNonCoveringZoomHorizontalTranslation] to determine the
  /// translation to apply when the child is smaller than the viewport
  /// horizontally.
  HorizontalNonCoveringZoomAlign get nonCoveringZoomAlignmentHorizontal;

  ///How to align the child on non covering zoom for Vertical axis
  ///
  /// Used by [getNonCoveringZoomVerticalTranslation] to determine the
  /// translation to apply when the child is smaller than the viewport
  /// vertically.
  VerticalNonCoveringZoomAlign get nonCoveringZoomAlignmentVertical;

  /// How to zoom out when double tapping
  ///
  /// Used by [doubleTabZoomOutScale] to determine the scale to zoom out to when double tapping
  DoubleTapZoomOutBehaviour get doubleTapZoomOutBehaviour;

  /// To determine the scale to zoom out to when double tapping
  @protected
  double get doubleTabZoomOutScale {
    switch (doubleTapZoomOutBehaviour) {
      case DoubleTapZoomOutBehaviour.zoomOutToMatchHeight:
        return widgetViewport.height / childBoundaryRect.height;
      case DoubleTapZoomOutBehaviour.zoomOutToMatchWidth:
        return widgetViewport.width / childBoundaryRect.width;
      case DoubleTapZoomOutBehaviour.zoomOutToMinScale:
        double widthScale = widgetViewport.width / childBoundaryRect.width;
        double heightScale = widgetViewport.height / childBoundaryRect.height;
        return math.min(widthScale, heightScale);
    }
  }

  /// Returns the translation to apply when the child is smaller than the viewport
  /// vertically.
  @protected
  double getNonCoveringZoomVerticalTranslation(double scale) {
    switch (nonCoveringZoomAlignmentVertical) {
      case VerticalNonCoveringZoomAlign.top:
        return 0;
      case VerticalNonCoveringZoomAlign.middle:
        return (widgetViewport.height - (childBoundaryRect.height * scale)) / 2;
      case VerticalNonCoveringZoomAlign.bottom:
        return widgetViewport.height - (childBoundaryRect.height * scale);
    }
  }

  /// Returns the translation to apply when the child is smaller than the viewport
  /// horizontally.
  @protected
  double getNonCoveringZoomHorizontalTranslation(double scale) {
    switch (nonCoveringZoomAlignmentHorizontal) {
      case HorizontalNonCoveringZoomAlign.left:
        return 0;
      case HorizontalNonCoveringZoomAlign.middle:
        return (widgetViewport.width - (childBoundaryRect.width * scale)) / 2;
      case HorizontalNonCoveringZoomAlign.right:
        return widgetViewport.width - (childBoundaryRect.width * scale);
    }
  }

  /// What should happen on transform change.
  @protected
  void updateTransform();

  // TODO(justinmc): Add rotateEnabled parameter to the widget and remove this
  // hardcoded value when the rotation feature is implemented.
  // https://github.com/flutter/flutter/issues/57698
  final bool _rotateEnabled = false;

  /// The _boundaryRect is calculated by adding the boundaryMargin to the size of
  /// the child.
  @protected
  Rect get childBoundaryRect {
    assert(childKey.currentContext != null);

    Size childSize;
    if (realChildSize != null) {
      childSize = realChildSize!;
    } else {
      final RenderBox childRenderBox =
          childKey.currentContext!.findRenderObject()! as RenderBox;
      childSize = childRenderBox.size;
    }
    Offset offset = Offset.zero;

    return offset & childSize;
  }

  // The Rect representing the child's parent.
  Rect get widgetViewport {
    assert(parentKey.currentContext != null);
    final RenderBox parentRenderBox =
        parentKey.currentContext!.findRenderObject()! as RenderBox;
    return Offset.zero & parentRenderBox.size;
  }

  /// Return a new matrix representing the given matrix after applying the given
  /// translation.
  @protected
  Matrix4 matrixTranslate(Matrix4 matrix, Offset translation) {
    if (translation == Offset.zero) {
      return matrix.clone();
    }

    late final Offset alignedTranslation;

    if (currentAxis != null) {
      switch (widget.panAxis) {
        case PanAxis.horizontal:
          alignedTranslation = alignAxis(translation, Axis.horizontal);
        case PanAxis.vertical:
          alignedTranslation = alignAxis(translation, Axis.vertical);
        case PanAxis.aligned:
          alignedTranslation = alignAxis(translation, currentAxis!);
        case PanAxis.free:
          alignedTranslation = translation;
      }
    } else {
      alignedTranslation = translation;
    }

    final Matrix4 nextMatrix = matrix.clone()
      ..translate(
        alignedTranslation.dx,
        alignedTranslation.dy,
      );

    // Transform the viewport to determine where its four corners will be after
    // the child has been transformed.
    final Quad nextViewport = transformViewport(nextMatrix, widgetViewport);

    // If the boundaries are infinite, then no need to check if the translation
    // fits within them.
    if (childBoundaryRect.isInfinite) {
      return nextMatrix;
    }

    // Expand the boundaries with rotation. This prevents the problem where a
    // mismatch in orientation between the viewport and boundaries effectively
    // limits translation. With this approach, all points that are visible with
    // no rotation are visible after rotation.
    final Quad boundariesAabbQuad = getAxisAlignedBoundingBoxWithRotation(
      childBoundaryRect,
      currentRotation,
    );

    // If the given translation fits completely within the boundaries, allow it.
    final Offset offendingDistance =
        exceedsBy(boundariesAabbQuad, nextViewport);
    if (offendingDistance == Offset.zero) {
      return nextMatrix;
    }

    // Desired translation goes out of bounds, so translate to the nearest
    // in-bounds point instead.
    final Offset nextTotalTranslation = getMatrixTranslation(nextMatrix);
    final double currentScale = matrix.getScaleOnZAxis();
    final Offset correctedTotalTranslation = Offset(
      nextTotalTranslation.dx - offendingDistance.dx * currentScale,
      nextTotalTranslation.dy - offendingDistance.dy * currentScale,
    );
    // TODO(justinmc): This needs some work to handle rotation properly. The
    // idea is that the boundaries are axis aligned (boundariesAabbQuad), but
    // calculating the translation to put the viewport inside that Quad is more
    // complicated than this when rotated.
    // https://github.com/flutter/flutter/issues/57698
    final Matrix4 correctedMatrix = matrix.clone()
      ..setTranslation(Vector3(
        correctedTotalTranslation.dx,
        correctedTotalTranslation.dy,
        0.0,
      ));

    // Double check that the corrected translation fits.
    final Quad correctedViewport =
        transformViewport(correctedMatrix, widgetViewport);
    final Offset offendingCorrectedDistance =
        exceedsBy(boundariesAabbQuad, correctedViewport);
    if (offendingCorrectedDistance == Offset.zero) {
      return correctedMatrix;
    }

    // If the corrected translation doesn't fit in either direction, don't allow
    // any translation at all. This happens when the viewport is larger than the
    // entire boundary.
    if (offendingCorrectedDistance.dx != 0.0 &&
        offendingCorrectedDistance.dy != 0.0) {
      return matrix.clone();
    }

    // Otherwise, allow translation in only the direction that fits. This
    // happens when the viewport is larger than the boundary in one direction.
    final Offset unidirectionalCorrectedTotalTranslation = Offset(
      offendingCorrectedDistance.dx == 0.0 ? correctedTotalTranslation.dx : 0.0,
      offendingCorrectedDistance.dy == 0.0 ? correctedTotalTranslation.dy : 0.0,
    );
    return matrix.clone()
      ..setTranslation(Vector3(
        unidirectionalCorrectedTotalTranslation.dx,
        unidirectionalCorrectedTotalTranslation.dy,
        0.0,
      ));
  }

  // Return a new matrix representing the given matrix after applying the given
  // scale.
  @protected
  Matrix4 matrixScale(Matrix4 matrix, double scale) {
    if (scale == 1.0) {
      return matrix.clone();
    }
    assert(scale != 0.0);

    // Don't allow a scale that results in an overall scale beyond min/max
    // scale.
    final double currentScale =
        transformationController!.value.getScaleOnZAxis();
    final double totalScale = math.max(
      currentScale * scale,
      // Ensure that the scale cannot make the child so **small** that it can't fit //Korrigiert von der originalversion
      // inside the boundaries (in either direction).
      math.max(
        widget.allowNonCoveringScreenZoom
            ? widget.minScale
            : (widgetViewport.width / childBoundaryRect.width),
        widget.allowNonCoveringScreenZoom
            ? widget.minScale
            : (widgetViewport.height / childBoundaryRect.height),
      ),
    );
    final double clampedTotalScale = clampDouble(
      totalScale,
      widget.minScale,
      widget.maxScale,
    );
    Vector3 translation = matrix.getTranslation();
    // If smaller than the viewport, set translation to 0
    if (clampedTotalScale <
        (widgetViewport.height / childBoundaryRect.height)) {
      translation.y = 0;
    }
    final double clampedScale = clampedTotalScale / currentScale;
    return matrix.clone()
      ..setTranslation(translation)
      ..scale(clampedScale);
  }

  /// Return a new matrix representing the given matrix after applying the given
  /// rotation.
  @protected
  Matrix4 matrixRotate(Matrix4 matrix, double rotation, Offset focalPoint) {
    if (rotation == 0) {
      return matrix.clone();
    }
    final Offset focalPointScene = transformationController!.toScene(
      focalPoint,
    );
    return matrix.clone()
      ..translate(focalPointScene.dx, focalPointScene.dy)
      ..rotateZ(-rotation)
      ..translate(-focalPointScene.dx, -focalPointScene.dy);
  }

  // Returns true if the given GestureType is enabled.
  @protected
  bool gestureIsSupported(GestureType? gestureType, {bool outer = false}) {
    switch (gestureType) {
      case GestureType.rotate:
        return _rotateEnabled;

      case GestureType.scale:
        return widget.scaleEnabled;

      case GestureType.pan:
      case null:
        if (widget.noMouseDragScroll && outer) {
          return false;
        }
        return widget.panEnabled;
    }
  }

  /// Decide which type of gesture this is by comparing the amount of scale
  /// and rotation in the gesture, if any. Scale starts at 1 and rotation
  /// starts at 0. Pan will have no scale and no rotation because it uses only one
  /// finger.
  GestureType getGestureType(ScaleUpdateDetails details) {
    final double scale = !widget.scaleEnabled ? 1.0 : details.scale;
    final double rotation = !_rotateEnabled ? 0.0 : details.rotation;
    if ((scale - 1).abs() > rotation.abs()) {
      return GestureType.scale;
    } else if (rotation != 0.0) {
      return GestureType.rotate;
    } else {
      return GestureType.pan;
    }
  }

  @protected
  void resetAnimation() {
    if (controller.isAnimating) {
      controller.stop();
      controller.reset();
      animation?.removeListener(onAnimate);
      animation = null;
    }
    if (scaleController.isAnimating) {
      scaleController.stop();
      scaleController.reset();
      scaleAnimation?.removeListener(onScaleAnimate);
      scaleAnimation = null;
    }
    afterAnimate();
  }

  /// Handle the start of a gesture. All of pan, scale, and rotate are handled
  /// with GestureDetector's scale gesture.
  @protected
  void onScaleStart(ScaleStartDetails details) {
    resetAnimation();

    gestureType = null;
    currentAxis = null;
    scaleStart = transformationController!.value.getScaleOnZAxis();
    referenceFocalPoint = transformationController!.toScene(
      details.localFocalPoint,
    );
    rotationStart = currentRotation;
  }

  /// Handle an update to an ongoing gesture. All of pan, scale, and rotate are
  /// handled with GestureDetector's scale gesture.
  @protected
  void onScaleUpdate(ScaleUpdateDetails details, {bool inner = false}) {
    final double scale = transformationController!.value.getScaleOnZAxis();
    scaleAnimationFocalPoint = details.localFocalPoint;
    final Offset focalPointScene = transformationController!.toScene(
      details.localFocalPoint,
    );

    if (gestureType == GestureType.pan) {
      // When a gesture first starts, it sometimes has no change in scale and
      // rotation despite being a two-finger gesture. Here the gesture is
      // allowed to be reinterpreted as its correct type after originally
      // being marked as a pan.
      gestureType = getGestureType(details);
    } else {
      gestureType ??= getGestureType(details);
    }
    if (!gestureIsSupported(gestureType, outer: inner)) {
      return;
    }

    switch (gestureType!) {
      case GestureType.scale:
        if (scaleStart == null) {
          return;
        }
        scrollbarController?.onScrollStart();
        // details.scale gives us the amount to change the scale as of the
        // start of this gesture, so calculate the amount to scale as of the
        // previous call to _onScaleUpdate.
        final double desiredScale = scaleStart! * details.scale;
        final double scaleChange = desiredScale / scale;
        transformationController!.value = matrixScale(
          transformationController!.value,
          scaleChange,
        );

        // While scaling, translate such that the user's two fingers stay on
        // the same places in the scene. That means that the focal point of
        // the scale should be on the same place in the scene before and after
        // the scale.
        // BUT when the user zooms out of his controllable area, the focal
        // point should always be in the middle of the screen so that the
        // child stays centered.
        final Offset focalPointSceneScaled = transformationController!.toScene(
          details.localFocalPoint,
        );
        transformationController!.value = matrixTranslate(
          transformationController!.value,
          focalPointSceneScaled - referenceFocalPoint!,
        );

        // details.localFocalPoint should now be at the same location as the
        // original _referenceFocalPoint point. If it's not, that's because
        // the translate came in contact with a boundary. In that case, update
        // _referenceFocalPoint so subsequent updates happen in relation to
        // the new effective focal point.
        final Offset focalPointSceneCheck = transformationController!.toScene(
          details.localFocalPoint,
        );
        if (round(referenceFocalPoint!) != round(focalPointSceneCheck)) {
          referenceFocalPoint = focalPointSceneCheck;
        }
        afterZoom();

      case GestureType.rotate:
        if (details.rotation == 0.0) {
          return;
        }
        scrollbarController?.onScrollStart();
        final double desiredRotation = rotationStart! + details.rotation;
        transformationController!.value = matrixRotate(
          transformationController!.value,
          currentRotation - desiredRotation,
          details.localFocalPoint,
        );
        currentRotation = desiredRotation;

      case GestureType.pan:
        if (referenceFocalPoint == null) {
          return;
        }
        currentAxis ??= getPanAxis(referenceFocalPoint!, focalPointScene);

        if (widget.panAxis == PanAxis.horizontal) {
          scrollbarController?.onScrollStartHorizontal();
        } else if (widget.panAxis == PanAxis.vertical) {
          scrollbarController?.onScrollStartVertical();
        } else if (widget.panAxis == PanAxis.free) {
          scrollbarController?.onScrollStart();
        } else if (widget.panAxis == PanAxis.aligned) {
          if (currentAxis == Axis.horizontal) {
            scrollbarController?.onScrollStartHorizontal();
          } else {
            scrollbarController?.onScrollStartVertical();
          }
        }
        // details may have a change in scale here when scaleEnabled is false.
        // In an effort to keep the behavior similar whether or not scaleEnabled
        // is true, these gestures are thrown away.
        if (details.scale != 1.0) {
          return;
        }
        // Translate so that the same point in the scene is underneath the
        // focal point before and after the movement.
        final Offset translationChange = focalPointScene - referenceFocalPoint!;
        transformationController!.value = matrixTranslate(
          transformationController!.value,
          translationChange,
        );
        referenceFocalPoint = transformationController!.toScene(
          details.localFocalPoint,
        );
    }
  }

  /// Handle the end of a gesture of _GestureType. All of pan, scale, and rotate
  /// are handled with GestureDetector's scale gesture.
  @protected
  void onScaleEnd(ScaleEndDetails details, {bool outer = false}) {
    scaleStart = null;
    rotationStart = null;
    referenceFocalPoint = null;

    animation?.removeListener(onAnimate);
    scaleAnimation?.removeListener(onScaleAnimate);
    controller.reset();
    scaleController.reset();

    if (!gestureIsSupported(gestureType, outer: outer)) {
      currentAxis = null;
      scrollbarController?.onScrollEnd();
      return;
    }

    if (gestureType == GestureType.pan) {
      if (details.velocity.pixelsPerSecond.distance < kMinFlingVelocity) {
        currentAxis = null;
        scrollbarController?.onScrollEnd();
        return;
      }
      final Vector3 translationVector =
          transformationController!.value.getTranslation();
      final Offset translation =
          Offset(translationVector.x, translationVector.y);
      final FrictionSimulation frictionSimulationX = FrictionSimulation(
        widget.interactionEndFrictionCoefficient,
        translation.dx,
        details.velocity.pixelsPerSecond.dx,
      );
      final FrictionSimulation frictionSimulationY = FrictionSimulation(
        widget.interactionEndFrictionCoefficient,
        translation.dy,
        details.velocity.pixelsPerSecond.dy,
      );
      final double tFinal = getFinalTime(
        details.velocity.pixelsPerSecond.distance,
        widget.interactionEndFrictionCoefficient,
      );
      animation = Tween<Offset>(
        begin: translation,
        end: Offset(frictionSimulationX.finalX, frictionSimulationY.finalX),
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.decelerate,
      ));
      controller.duration = Duration(milliseconds: (tFinal * 1000).round());
      animation!.addListener(onAnimate);
      controller.forward();
    } else if (gestureType == GestureType.scale) {
      if (details.scaleVelocity.abs() < 0.1) {
        currentAxis = null;
        scrollbarController?.onScrollEnd();
        return;
      }
      final double scale = transformationController!.value.getScaleOnZAxis();
      final FrictionSimulation frictionSimulation = FrictionSimulation(
          widget.interactionEndFrictionCoefficient * widget.scaleFactor,
          scale,
          details.scaleVelocity / 10);
      final double tFinal = getFinalTime(
          details.scaleVelocity.abs(), widget.interactionEndFrictionCoefficient,
          effectivelyMotionless: 0.1);
      scaleAnimation =
          Tween<double>(begin: scale, end: frictionSimulation.x(tFinal))
              .animate(CurvedAnimation(
                  parent: scaleController, curve: Curves.decelerate));
      scaleController.duration =
          Duration(milliseconds: (tFinal * 1000).round());
      scaleAnimation!.addListener(onScaleAnimate);
      scaleController.forward();
    } else {
      scrollbarController?.onScrollEnd();
    }
  }

  ///Used to check if ctrl or shift for scrolling is pressed
  @protected
  bool onKey(KeyEvent event) {
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.controlLeft ||
        key == LogicalKeyboardKey.controlRight) {
      if (event is KeyDownEvent || event is KeyRepeatEvent) {
        _ctrlPressed = true;
      } else if (event is KeyUpEvent) {
        _ctrlPressed = false;
      }
    }

    if (key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight) {
      if (event is KeyDownEvent || event is KeyRepeatEvent) {
        _shiftPressed = true;
      } else if (event is KeyUpEvent) {
        _shiftPressed = false;
      }
    }

    return false;
  }

  bool _ctrlPressed = false;
  bool _shiftPressed = false;

  /// Handle mousewheel and web trackpad scroll events.
  @protected
  void receivedPointerSignal(PointerSignalEvent event) {
    final double scaleChange;
    if (event is PointerScrollEvent) {
      if (!_ctrlPressed) {
        // Normal scroll, so treat it as a pan.
        if (!gestureIsSupported(GestureType.pan)) {
          return;
        }

        Offset scrollDelta = event.scrollDelta;
        //Shift pressed, so scroll horizontally with the mousewheel
        if (event.kind != PointerDeviceKind.trackpad && _shiftPressed) {
          scrollDelta = Offset(scrollDelta.dy, scrollDelta.dx);
          scrollbarController?.onScrollStartHorizontal();
        } else {
          scrollbarController?.onScrollStartVertical();
        }

        final Offset localDelta = PointerEvent.transformDeltaViaPositions(
          untransformedEndPosition: event.position + scrollDelta,
          untransformedDelta: scrollDelta,
          transform: event.transform,
        );

        final Offset focalPointScene = transformationController!.toScene(
          event.localPosition,
        );

        final Offset newFocalPointScene = transformationController!.toScene(
          event.localPosition - localDelta,
        );

        transformationController!.value = matrixTranslate(
            transformationController!.value,
            newFocalPointScene - focalPointScene);
        scrollbarController?.onScrollEnd();
        return;
      }
      // Ignore left and right mouse wheel scroll.
      if (event.scrollDelta.dy == 0.0) {
        return;
      }
      scaleChange = math.exp(-event.scrollDelta.dy / widget.scaleFactor);
    } else if (event is PointerScaleEvent) {
      scaleChange = event.scale;
    } else {
      return;
    }

    if (!gestureIsSupported(GestureType.scale)) {
      return;
    }
    scrollbarController?.onScrollStart();

    final Offset focalPointScene = transformationController!.toScene(
      event.localPosition,
    );

    transformationController!.value = matrixScale(
      transformationController!.value,
      scaleChange,
    );

    // After scaling, translate such that the event's position is at the
    // same scene point before and after the scale.
    final Offset focalPointSceneScaled = transformationController!.toScene(
      event.localPosition,
    );
    transformationController!.value = matrixTranslate(
      transformationController!.value,
      focalPointSceneScaled - focalPointScene,
    );

    afterZoom();
    scrollbarController?.onScrollEnd();
  }

  /// Used for getting position of double tap for zoom in and out
  @protected
  TapDownDetails? doubleTapDetails;

  @protected
  void handleDoubleTap() {
    if (doubleTapDetails == null) {
      return;
    }
    final double currentScale =
        transformationController!.value.getScaleOnZAxis();
    final double pos1Scale = doubleTabZoomOutScale;
    const double pos2Scale = 1;
    final position = doubleTapDetails!.localPosition;

    //Zoom to no zoom when a) the user is already zoomed out or b)
    //the user is zoomed in and the table is bigger than standard size

    //Because we cant compare doubles, we have to check if the difference is smaller than 0.01 (no noticeable difference for the user)
    final bool zoomToNormal =
        ((currentScale - pos1Scale).abs() < 0.01) || currentScale > pos2Scale;

    final double scaleChange =
        (zoomToNormal ? pos2Scale : pos1Scale) / currentScale;

    Matrix4 newM = getScaled(scale: scaleChange);
    animateTo(newM, noTranslation: true, focalPoint: position);
  }

  /// Automatically animates to a new point
  ///
  /// Please dont include any focal point tracking in this function, because it is calculated automatically
  /// If you do not include translation or zoom, please disable it by setting noTranslation or noZoom to true
  /// Please set focalPoint to the position of the zoom if you want to zoom, otherwise set noZoom to true
  void animateTo(Matrix4 newMatrix,
      {Duration duration = const Duration(milliseconds: 150),
      Curve curve = Curves.linear,
      bool noTranslation = false,
      noZoom = false,
      Offset? focalPoint}) {
    assert(!(noTranslation && noZoom),
        "Please dont disable both translation and zoom, because then the animation would be useless");
    assert(noZoom || focalPoint != null,
        "Please provide a focal point for zooming");
    resetAnimation();
    if (!noZoom) {
      scaleAnimationFocalPoint = focalPoint!;
    }
    scaleStart = null;
    rotationStart = null;
    referenceFocalPoint = null;

    animation?.removeListener(onAnimate);
    scaleAnimation?.removeListener(onScaleAnimate);
    controller.reset();
    scaleController.reset();

    if (!noTranslation) {
      Offset translation = getMatrixTranslation(newMatrix);
      Offset oldTranslation =
          getMatrixTranslation(transformationController!.value);
      animation = Tween<Offset>(
        begin: oldTranslation,
        end: translation,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: curve,
      ));
      controller.duration = duration;
    }

    if (!noZoom) {
      double scale = newMatrix.getScaleOnZAxis();
      double oldScale = transformationController!.value.getScaleOnZAxis();

      scaleAnimation = Tween<double>(begin: oldScale, end: scale)
          .animate(CurvedAnimation(parent: scaleController, curve: curve));
      scaleController.duration = duration;
    }

    setToAfterAnimate = getScaled(
        position: focalPoint,
        matrixZoomedNeedToApplyFocalPointTracking: newMatrix);

    scrollbarController?.onScrollStart();
    if (!noTranslation) {
      animation!.addListener(onAnimate);
      controller.forward();
    }
    if (!noZoom) {
      scaleAnimation!.addListener(onScaleAnimate);
      scaleController.forward();
    }
  }

  @protected
  Matrix4? setToAfterAnimate;

  @protected
  void afterAnimate() {
    if (setToAfterAnimate != null) {
      transformationController!.value = setToAfterAnimate!;
      setToAfterAnimate = null;
    }
    scrollbarController?.onScrollEnd();
  }

  @protected
  Matrix4 getScaled(
      {double? scale,
      Offset? position,
      Matrix4? matrixZoomedNeedToApplyFocalPointTracking}) {
    Matrix4 newM;
    if (scale != null) {
      newM = matrixScale(
        transformationController!.value,
        scale,
      );
    } else {
      newM = matrixZoomedNeedToApplyFocalPointTracking!;
    }

    if (position != null) {
      Offset referenceFocalPoint = transformationController!.toScene(
        position,
      );

      // While scaling, translate such that the user's two fingers stay on
      // the same places in the scene. That means that the focal point of
      // the scale should be on the same place in the scene before and after
      // the scale.
      // BUT when the user zooms out of his controllable area, the focal
      // point should always be in the middle of the screen so that the
      // child stays centered.
      final Offset focalPointSceneScaled = newM.toScene(
        position,
      );

      newM = matrixTranslate(
        newM,
        focalPointSceneScaled - referenceFocalPoint,
      );
    }
    return newM;
  }

  /// Handle inertia drag animation.
  @protected
  void onAnimate() {
    if (!controller.isAnimating) {
      currentAxis = null;
      animation?.removeListener(onAnimate);
      animation = null;
      controller.reset();
      afterAnimate();
      return;
    }
    // Translate such that the resulting translation is _animation.value.
    final Vector3 translationVector =
        transformationController!.value.getTranslation();
    final Offset translation = Offset(translationVector.x, translationVector.y);
    final Offset translationScene = transformationController!.toScene(
      translation,
    );
    final Offset animationScene = transformationController!.toScene(
      animation!.value,
    );
    final Offset translationChangeScene = animationScene - translationScene;
    transformationController!.value = matrixTranslate(
      transformationController!.value,
      translationChangeScene,
    );
  }

  /// Handle inertia scale animation.
  @protected
  void onScaleAnimate() {
    if (!scaleController.isAnimating) {
      currentAxis = null;
      scaleAnimation?.removeListener(onScaleAnimate);
      scaleAnimation = null;
      scaleController.reset();
      afterAnimate();
      return;
    }
    final double desiredScale = scaleAnimation!.value;
    final double scaleChange =
        desiredScale / transformationController!.value.getScaleOnZAxis();
    final Offset referenceFocalPoint = transformationController!.toScene(
      scaleAnimationFocalPoint,
    );
    transformationController!.value = matrixScale(
      transformationController!.value,
      scaleChange,
    );

    // While scaling, translate such that the user's two fingers stay on
    // the same places in the scene. That means that the focal point of
    // the scale should be on the same place in the scene before and after
    // the scale.
    final Offset focalPointSceneScaled = transformationController!.toScene(
      scaleAnimationFocalPoint,
    );
    transformationController!.value = matrixTranslate(
      transformationController!.value,
      focalPointSceneScaled - referenceFocalPoint,
    );
  }

  @override
  void initState() {
    super.initState();

    transformationController =
        widget.transformationController ?? TransformationController();
    transformationController!.addListener(updateTransform);
    controller = AnimationController(vsync: this);
    scaleController = AnimationController(vsync: this);
    ServicesBinding.instance.keyboard.addHandler(onKey);
  }

  void setScrollbarControllers() {
    if (!widget.showScrollbars) {
      if (scrollbarController != null) {
        scrollbarController!.dispose();
      }
      scrollbarController = null;
      return;
    }
    scrollbarController ??= getPlatformScrollbarController(
      vsync: this,
      controlInterface: CustomTransformScrollbarWidgetInterface(
        fgetTransform: () => transformationController!.value,
        fgetViewport: () => widgetViewport.size,
        fgetContent: () => childBoundaryRect.size,
        fcontext: () => context,
        fjumpVertical: (v) {
          transformationController!.value = matrixTranslate(
              transformationController!.value,
              Offset(0, v / transformationController!.value.getScaleOnZAxis()));
        },
        fjumpHorizontal: (h) {
          transformationController!.value = matrixTranslate(
              transformationController!.value,
              Offset(h / transformationController!.value.getScaleOnZAxis(), 0));
        },
        fanimateVertical: (v, d, c) {
          Matrix4 newTransform = matrixTranslate(
              transformationController!.value,
              Offset(
                  0, -v / transformationController!.value.getScaleOnZAxis()));
          animateTo(newTransform, duration: d, curve: c, noZoom: true);
        },
        fanimateHorizontal: (h, d, c) {
          Matrix4 newTransform = matrixTranslate(
              transformationController!.value,
              Offset(
                  -h / transformationController!.value.getScaleOnZAxis(), 0));
          animateTo(newTransform, duration: d, curve: c, noZoom: true);
        },
      ),
    );
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Handle all cases of needing to dispose and initialize
    // transformationControllers.
    if (oldWidget.transformationController == null) {
      if (widget.transformationController != null) {
        transformationController!.removeListener(updateTransform);
        transformationController!.dispose();
        transformationController = widget.transformationController;
        transformationController!.addListener(updateTransform);
      }
    } else {
      if (widget.transformationController == null) {
        transformationController!.removeListener(updateTransform);
        transformationController = TransformationController();
        transformationController!.addListener(updateTransform);
      } else if (widget.transformationController !=
          oldWidget.transformationController) {
        transformationController!.removeListener(updateTransform);
        transformationController = widget.transformationController;
        transformationController!.addListener(updateTransform);
      }
    }

    if (oldWidget.showScrollbars != widget.showScrollbars) {
      setScrollbarControllers();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setScrollbarControllers();
    scrollbarController?.onDidChangeDependencies();
  }

  @override
  void dispose() {
    controller.dispose();
    scaleController.dispose();
    transformationController!.removeListener(updateTransform);
    if (widget.transformationController == null) {
      transformationController!.dispose();
    }
    scrollbarController?.dispose();
    ServicesBinding.instance.keyboard.removeHandler(onKey);
    super.dispose();
  }

  /// Builds the child.
  ///
  /// Please use [childKey] as the key of the child, so that this widget can calculate its size.
  ///
  /// Is only called from [build], so that the gesture detectors for the zoom and pan gestures can be set up automatically.
  /// If you decide to handle that yourself, there is no need to provide an actual implementation here.
  Widget buildChild(BuildContext context);

  /// Gets called from the default [build] function with the result of [buildChild]
  /// as the [child] parameter.
  ///
  /// This function is used to build the actual widget with the scrollbars and the transformation.
  /// If your child applies the transform itself, you can just return the child.
  Widget buildTransformAndScrollbars(BuildContext context, Widget child);

  ///Build the Widget.
  ///Instead of overriding this function, override [buildChild] so that all gesture detectors can be set up automatically.
  @override
  Widget build(BuildContext context) {
    ExtendedTransformScrollbarController? scrollbarController =
        this.scrollbarController;
    scrollbarController?.updateScrollbarPainters();
    Widget child = buildChild(context);
    child = buildTransformAndScrollbars(context, child);

    if (scrollbarController != null) {
      child = RawGestureDetector(
        gestures: scrollbarController.getGesturesVertical(context),
        child: MouseRegion(
          onExit: (PointerExitEvent event) {
            switch (event.kind) {
              case PointerDeviceKind.mouse:
              case PointerDeviceKind.trackpad:
                if (scrollbarController.enableGestures) {
                  scrollbarController.handleHoverExit(event);
                }
              case PointerDeviceKind.stylus:
              case PointerDeviceKind.invertedStylus:
              case PointerDeviceKind.unknown:
              case PointerDeviceKind.touch:
                break;
            }
          },
          onHover: (PointerHoverEvent event) {
            switch (event.kind) {
              case PointerDeviceKind.mouse:
              case PointerDeviceKind.trackpad:
                if (scrollbarController.enableGestures) {
                  scrollbarController.handleHover(event);
                }
              case PointerDeviceKind.stylus:
              case PointerDeviceKind.invertedStylus:
              case PointerDeviceKind.unknown:
              case PointerDeviceKind.touch:
                break;
            }
          },
          child: child,
        ),
      );
      child = RawGestureDetector(
        gestures: scrollbarController.getGesturesHorizontal(context),
        child: child,
      );
    }

    if (!widget.noMouseDragScroll) {
      child = GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Necessary when panning off screen.
        onScaleEnd: (onScaleEnd),
        onScaleStart: onScaleStart,
        onScaleUpdate: onScaleUpdate,
        onDoubleTapDown:
            widget.doubleTapToZoom ? ((d) => doubleTapDetails = d) : null,
        onDoubleTap: widget.doubleTapToZoom ? handleDoubleTap : null,
        child: child,
      );
    } else {
      child = GestureDetector(
        behavior: HitTestBehavior.opaque,
        supportedDevices: const {
          PointerDeviceKind.touch,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.stylus,
          PointerDeviceKind.invertedStylus,
          PointerDeviceKind.unknown,
        },
        onScaleEnd: onScaleEnd,
        onScaleStart: onScaleStart,
        onScaleUpdate: onScaleUpdate,
        child: child,
      );
      child = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onScaleEnd: (d) {
          onScaleEnd(d, outer: true);
        },
        onScaleStart: onScaleStart,
        onScaleUpdate: (d) {
          onScaleUpdate(d, inner: true);
        },
        onDoubleTapDown:
            widget.doubleTapToZoom ? ((d) => doubleTapDetails = d) : null,
        onDoubleTap: widget.doubleTapToZoom ? handleDoubleTap : null,
        child: child,
      );
    }

    return Listener(
      key: parentKey,
      onPointerSignal: receivedPointerSignal,
      child: child,
    );
  }
}

enum HorizontalNonCoveringZoomAlign {
  left,
  middle,
  right,
}

enum VerticalNonCoveringZoomAlign {
  top,
  middle,
  bottom,
}

enum DoubleTapZoomOutBehaviour {
  zoomOutToMatchWidth,
  zoomOutToMatchHeight,

  ///Zooms out the child to the minimum scale where it touches the viewport borders, but is completely visible
  zoomOutToMinScale,
}

// A classification of relevant user gestures. Each contiguous user gesture is
// represented by exactly one _GestureType.
enum GestureType {
  pan,
  scale,
  rotate,
}

// Given a velocity and drag, calculate the time at which motion will come to
// a stop, within the margin of effectivelyMotionless.
double getFinalTime(double velocity, double drag,
    {double effectivelyMotionless = 10}) {
  return math.log(effectivelyMotionless / velocity) / math.log(drag / 100);
}

// Return the translation from the given Matrix4 as an Offset.
Offset getMatrixTranslation(Matrix4 matrix) {
  final Vector3 nextTranslation = matrix.getTranslation();
  return Offset(nextTranslation.x, nextTranslation.y);
}

// Transform the four corners of the viewport by the inverse of the given
// matrix. This gives the viewport after the child has been transformed by the
// given matrix. The viewport transforms as the inverse of the child (i.e.
// moving the child left is equivalent to moving the viewport right).
Quad transformViewport(Matrix4 matrix, Rect viewport) {
  final Matrix4 inverseMatrix = matrix.clone()..invert();
  return Quad.points(
    inverseMatrix.transform3(Vector3(
      viewport.topLeft.dx,
      viewport.topLeft.dy,
      0.0,
    )),
    inverseMatrix.transform3(Vector3(
      viewport.topRight.dx,
      viewport.topRight.dy,
      0.0,
    )),
    inverseMatrix.transform3(Vector3(
      viewport.bottomRight.dx,
      viewport.bottomRight.dy,
      0.0,
    )),
    inverseMatrix.transform3(Vector3(
      viewport.bottomLeft.dx,
      viewport.bottomLeft.dy,
      0.0,
    )),
  );
}

// Find the axis aligned bounding box for the rect rotated about its center by
// the given amount.
Quad getAxisAlignedBoundingBoxWithRotation(Rect rect, double rotation) {
  final Matrix4 rotationMatrix = Matrix4.identity()
    ..translate(rect.size.width / 2, rect.size.height / 2)
    ..rotateZ(rotation)
    ..translate(-rect.size.width / 2, -rect.size.height / 2);
  final Quad boundariesRotated = Quad.points(
    rotationMatrix.transform3(Vector3(rect.left, rect.top, 0.0)),
    rotationMatrix.transform3(Vector3(rect.right, rect.top, 0.0)),
    rotationMatrix.transform3(Vector3(rect.right, rect.bottom, 0.0)),
    rotationMatrix.transform3(Vector3(rect.left, rect.bottom, 0.0)),
  );
  return BetterInteractiveViewerBase.getAxisAlignedBoundingBox(
      boundariesRotated);
}

// Return the amount that viewport lies outside of boundary. If the viewport
// is completely contained within the boundary (inclusively), then returns
// Offset.zero.
Offset exceedsBy(Quad boundary, Quad viewport) {
  final List<Vector3> viewportPoints = <Vector3>[
    viewport.point0,
    viewport.point1,
    viewport.point2,
    viewport.point3,
  ];
  Offset largestExcess = Offset.zero;
  for (final Vector3 point in viewportPoints) {
    final Vector3 pointInside =
        BetterInteractiveViewerBase.getNearestPointInside(point, boundary);
    final Offset excess = Offset(
      pointInside.x - point.x,
      pointInside.y - point.y,
    );
    if (excess.dx.abs() > largestExcess.dx.abs()) {
      largestExcess = Offset(excess.dx, largestExcess.dy);
    }
    if (excess.dy.abs() > largestExcess.dy.abs()) {
      largestExcess = Offset(largestExcess.dx, excess.dy);
    }
  }

  return round(largestExcess);
}

// Round the output values. This works around a precision problem where
// values that should have been zero were given as within 10^-10 of zero.
Offset round(Offset offset) {
  return Offset(
    double.parse(offset.dx.toStringAsFixed(9)),
    double.parse(offset.dy.toStringAsFixed(9)),
  );
}

// Align the given offset to the given axis by allowing movement only in the
// axis direction.
Offset alignAxis(Offset offset, Axis axis) {
  switch (axis) {
    case Axis.horizontal:
      return Offset(offset.dx, 0.0);
    case Axis.vertical:
      return Offset(0.0, offset.dy);
  }
}

// Given two points, return the axis where the distance between the points is
// greatest. If they are equal, return null.
Axis? getPanAxis(Offset point1, Offset point2) {
  if (point1 == point2) {
    return null;
  }
  final double x = point2.dx - point1.dx;
  final double y = point2.dy - point1.dy;
  return x.abs() > y.abs() ? Axis.horizontal : Axis.vertical;
}

extension Matrix4ToSceneOffset on Matrix4 {
  Offset toScene(Offset viewportPoint) {
    // On viewportPoint, perform the inverse transformation of the scene to get
    // where the point would be in the scene before the transformation.
    final Matrix4 inverseMatrix = Matrix4.inverted(this);
    final Vector3 untransformed = inverseMatrix.transform3(Vector3(
      viewportPoint.dx,
      viewportPoint.dy,
      0,
    ));
    return Offset(untransformed.x, untransformed.y);
  }
}
