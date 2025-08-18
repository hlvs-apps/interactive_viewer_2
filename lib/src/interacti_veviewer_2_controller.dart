import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:interactive_viewer_2/interactive_dev.dart';
import 'package:vector_math/vector_math_64.dart';

/// A thin wrapper on [ValueNotifier] whose value is a [Matrix4] representing a
/// transformation.
///
/// The [value] defaults to the identity matrix, which corresponds to no
/// transformation.
///
/// See also:
///
///  * [InteractiveViewer.controller] for detailed documentation
///    on how to use InteractiveViewer2Controller with [InteractiveViewer2].
class InteractiveViewer2Controller extends ValueNotifier<Matrix4> {
  /// The maximum allowed scale.
  ///
  /// The scale will be clamped between this and [minScale] inclusively.
  ///
  /// Defaults to 2.5.
  ///
  /// Must be greater than zero and greater than [minScale].
  late double maxScale;

  /// The minimum allowed scale.
  ///
  /// The scale will be clamped between this and [maxScale] inclusively.
  ///
  /// Defaults to 0.8.
  ///
  /// Must be a finite number greater than zero and less than [maxScale].
  late double minScale;

  Axis? currentAxis; // Used with panAxis.

  late Rect widgetViewport;

  late Rect childBoundaryRect;

  double currentRotation = 0.0; // Rotation of _transformationController.value.

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
  late PanAxis panAxis;

  /// Allows the user to zoom out the child so that it is displayed smaller than the viewports width and height.
  late bool allowNonCoveringScreenZoom;

  /// Create an instance of [InteractiveViewer2Controller].
  ///
  /// The [value] defaults to the identity matrix, which corresponds to no
  /// transformation.
  InteractiveViewer2Controller([
    Matrix4? value,
  ]) : super(value ?? Matrix4.identity());

  void setValues({
    required double minScale,
    required double maxScale,
    required PanAxis panAxis,
    required Axis? currentAxis,
    required Rect widgetViewport,
    required Rect childBoundaryRect,
    required double currentRotation,
    required bool allowNonCoveringScreenZoom,
  }) {
    this.panAxis = panAxis;
    this.minScale = minScale;
    this.maxScale = maxScale;
    this.currentAxis = currentAxis;
    this.widgetViewport = widgetViewport;
    this.currentRotation = currentRotation;
    this.childBoundaryRect = childBoundaryRect;
    this.allowNonCoveringScreenZoom = allowNonCoveringScreenZoom;
  }

  void zoomIn(double scale) {
    value = matrixScale(value, scale);
  }

  void zoomOut(double scale) {
    value = matrixScale(value, scale);
  }

  void pan(Offset offset) {
    value = matrixTranslate(value, offset);
  }

  /// Return the scene point at the given viewport point.
  ///
  /// A viewport point is relative to the parent while a scene point is relative
  /// to the child, regardless of transformation. Calling toScene with a
  /// viewport point essentially returns the scene coordinate that lies
  /// underneath the viewport point given the transform.
  ///
  /// The viewport transforms as the inverse of the child (i.e. moving the child
  /// left is equivalent to moving the viewport right).
  ///
  /// This method is often useful when determining where an event on the parent
  /// occurs on the child. This example shows how to determine where a tap on
  /// the parent occurred on the child.
  ///
  /// ```dart
  /// @override
  /// Widget build(BuildContext context) {
  ///   return GestureDetector(
  ///     onTapUp: (TapUpDetails details) {
  ///       _childWasTappedAt = _controller.toScene(
  ///         details.localPosition,
  ///       );
  ///     },
  ///     child: Interactive2Viewer(
  ///       controller: _controller,
  ///       child: child,
  ///     ),
  ///   );
  /// }
  /// ```
  Offset toScene(Offset viewportPoint) {
    // On viewportPoint, perform the inverse transformation of the scene to get
    // where the point would be in the scene before the transformation.
    final Matrix4 inverseMatrix = Matrix4.inverted(value);
    final Vector3 untransformed = inverseMatrix.transform3(
      Vector3(viewportPoint.dx, viewportPoint.dy, 0),
    );
    return Offset(untransformed.x, untransformed.y);
  }

  /// Return a new matrix representing the given matrix after applying the given
  /// rotation.
  Matrix4 matrixRotate(Matrix4 matrix, double rotation, Offset focalPoint) {
    if (rotation == 0) {
      return matrix.clone();
    }
    final Offset focalPointScene = toScene(focalPoint);

    return matrix.clone()
      ..translateByDouble(focalPointScene.dx, focalPointScene.dy, 0, 1)
      ..rotateZ(-rotation)
      ..translateByDouble(-focalPointScene.dx, -focalPointScene.dy, 0, 1);
  }

  // Return a new matrix representing the given matrix after applying the given
  // scale.
  Matrix4 matrixScale(Matrix4 matrix, double scale) {
    if (scale == 1.0) {
      return matrix.clone();
    }
    assert(scale != 0.0);

    // Don't allow a scale that results in an overall scale beyond min/max
    // scale.
    final double currentScale = value.getScaleOnZAxis();

    final double totalScale = math.max(
      currentScale * scale,
      // Ensure that the scale cannot make the child so **small** that it can't fit //Korrigiert von der originalversion
      // inside the boundaries (in either direction).
      math.max(
        allowNonCoveringScreenZoom
            ? minScale
            : (widgetViewport.width / childBoundaryRect.width),
        allowNonCoveringScreenZoom
            ? minScale
            : (widgetViewport.height / childBoundaryRect.height),
      ),
    );

    final double clampedTotalScale = clampDouble(
      totalScale,
      minScale,
      maxScale,
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
  /// translation.
  Matrix4 matrixTranslate(Matrix4 matrix, Offset translation) {
    if (translation == Offset.zero) {
      return matrix.clone();
    }

    late final Offset alignedTranslation;

    if (currentAxis != null) {
      alignedTranslation = switch (panAxis) {
        PanAxis.horizontal => alignAxis(translation, Axis.horizontal),
        PanAxis.vertical => alignAxis(translation, Axis.vertical),
        PanAxis.aligned => alignAxis(translation, currentAxis!),
        PanAxis.free => translation,
      };
    } else {
      alignedTranslation = translation;
    }

    final Matrix4 nextMatrix = matrix.clone()
      ..translateByDouble(alignedTranslation.dx, alignedTranslation.dy, 0, 1);

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
}
