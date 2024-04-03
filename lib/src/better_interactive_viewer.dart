library interactive_viewer_2;

import 'package:flutter/material.dart';
import 'scrollbars/transform_and_scrollbars_widget.dart';
import 'better_interactive_viewer_base.dart';

abstract class BetterInteractiveViewer extends BetterInteractiveViewerBase {
  /// The horizontal alignment of the non-covering zoom.
  /// Non covering zoom is the zoom that happens when the child is smaller than the viewport.
  final HorizontalNonCoveringZoomAlign nonCoveringZoomAlignmentHorizontal;

  /// The vertical alignment of the non-covering zoom.
  /// Non covering zoom is the zoom that happens when the child is smaller than the viewport.
  final VerticalNonCoveringZoomAlign nonCoveringZoomAlignmentVertical;

  /// What should happen when the user double taps to zoom out.
  final DoubleTapZoomOutBehaviour doubleTapZoomOutBehaviour;
  
  /// How to clip the content.
  final Clip clipBehavior;

  BetterInteractiveViewer({
    super.key,
    super.allowNonCoveringScreenZoom,
    super.panAxis,
    super.maxScale,
    super.minScale,
    super.interactionEndFrictionCoefficient,
    super.panEnabled,
    super.scaleEnabled,
    super.showScrollbars,
    super.noMouseDragScroll,
    super.scaleFactor,
    super.doubleTapToZoom,
    super.transformationController,
    this.nonCoveringZoomAlignmentHorizontal =
        HorizontalNonCoveringZoomAlign.middle,
    this.nonCoveringZoomAlignmentVertical = VerticalNonCoveringZoomAlign.middle,
    this.doubleTapZoomOutBehaviour =
        DoubleTapZoomOutBehaviour.zoomOutToMinScale,
    this.clipBehavior = Clip.none,
  });

  @override
  BetterInteractiveViewerState<BetterInteractiveViewer> createState();
}

abstract class BetterInteractiveViewerState <T extends BetterInteractiveViewer>
    extends BetterInteractiveViewerBaseState<T> {
  
  /// Gets the child. Child gets wrapped in a KeyedSubtree in [buildChild].
  Widget buildUnKeyedChild(BuildContext context);

  @override
  Widget buildChild(BuildContext context) {
    return KeyedSubtree(
      key: childKey,
      child: buildUnKeyedChild(context),
    );
  }

  @override
  Widget buildTransformAndScrollbars(BuildContext context, Widget child) {
    return TransformAndScrollbarsWidget(
      scrollbarController: scrollbarController,
      transform: transformForRender,
      onResize: () => Future.microtask(afterResize),
      child: child,
    );
  }

  @override
  HorizontalNonCoveringZoomAlign get nonCoveringZoomAlignmentHorizontal =>
      widget.nonCoveringZoomAlignmentHorizontal;

  @override
  VerticalNonCoveringZoomAlign get nonCoveringZoomAlignmentVertical =>
      widget.nonCoveringZoomAlignmentVertical;

  @override
  void updateTransform() {
    setState(() {});
  }

  @override
  DoubleTapZoomOutBehaviour get doubleTapZoomOutBehaviour =>
      widget.doubleTapZoomOutBehaviour;
  
  @override
  Widget build(BuildContext context) {
    return ClipRect(
      clipBehavior: widget.clipBehavior,
      child: super.build(context),
    );
  }
}
