//Copied and modified from flutter Transform widget source code

import 'package:flutter/material.dart';
import 'transform_scrollbar_controller.dart';
import 'transform_and_scrollbars_render_object_widget.dart';

class TransformAndScrollbarsWidget extends SingleChildRenderObjectWidget {
  /// Creates a widget that transforms its child.
  const TransformAndScrollbarsWidget({
    super.key,
    required this.transform,
    required this.scrollbarController,
    this.origin,
    this.alignment,
    this.transformHitTests = true,
    this.onResize,
    this.overrideSize,
    this.constrained = false,
    super.child,
  });

  /// The scrollbars to paint on the child.
  final BaseTransformScrollbarController? scrollbarController;

  /// The matrix to transform the child by during painting.
  final Matrix4 transform;

  /// The origin of the coordinate system (relative to the upper left corner of
  /// this render object) in which to apply the matrix.
  ///
  /// Setting an origin is equivalent to conjugating the transform matrix by a
  /// translation. This property is provided just for convenience.
  final Offset? origin;

  /// The alignment of the origin, relative to the size of the box.
  ///
  /// This is equivalent to setting an origin based on the size of the box.
  /// If it is specified at the same time as the [origin], both are applied.
  ///
  /// An [AlignmentDirectional.centerStart] value is the same as an [Alignment]
  /// whose [Alignment.x] value is `-1.0` if [Directionality.of] returns
  /// [TextDirection.ltr], and `1.0` if [Directionality.of] returns
  /// [TextDirection.rtl].	 Similarly [AlignmentDirectional.centerEnd] is the
  /// same as an [Alignment] whose [Alignment.x] value is `1.0` if
  /// [Directionality.of] returns	 [TextDirection.ltr], and `-1.0` if
  /// [Directionality.of] returns [TextDirection.rtl].
  final AlignmentGeometry? alignment;

  /// Whether to apply the transformation when performing hit tests.
  final bool transformHitTests;

  final Function({Size? size})? onResize;

  /// Override the size of the child. The child will be forced to have this size.
  final Size? overrideSize;

  /// Whether the child should be constrained to the size of this widget.
  final bool constrained;

  @override
  RenderTransformAndScrollbarsWidget createRenderObject(BuildContext context) {
    return RenderTransformAndScrollbarsWidget(
      transform: transform,
      origin: origin,
      alignment: alignment,
      textDirection: Directionality.maybeOf(context),
      transformHitTests: transformHitTests,
      scrollbarController: scrollbarController,
      onResize: onResize,
      overrideSize: overrideSize,
      constrained: constrained,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderTransformAndScrollbarsWidget renderObject) {
    renderObject
      ..transform = transform
      ..origin = origin
      ..alignment = alignment
      ..textDirection = Directionality.maybeOf(context)
      ..transformHitTests = transformHitTests
      ..scrollbarController = scrollbarController
      ..onResize = onResize
      ..overrideSize = overrideSize
      ..constrained = constrained;
  }
}
