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
    super.controller,
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

abstract class BetterInteractiveViewerState<T extends BetterInteractiveViewer>
    extends BetterInteractiveViewerBaseState<T> {
  /// Used to notify to rebuild the the transform without rebuilding the child and the listeners.
  @protected
  final RebuildNotifier rebuildNotifier = RebuildNotifier();

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
  void dispose() {
    rebuildNotifier.dispose();
    super.dispose();
  }

  /// If not null, overrides the size of the child.
  Size? get overrideSize;

  @override
  Size? get realChildSize => overrideSize ?? super.realChildSize;

  /// Gets called every time the transform changes. Can be used to display a widget
  /// over the scrollbars and the transformed widget, e.g. a indicator for the zoom.
  ///
  /// Instead of overriding [buildTransformAndScrollbars], consider overriding
  /// this method.
  ///
  /// The default implementation just returns the child.
  Widget buildAroundTransformAndScrollbar(BuildContext context, Widget child) {
    return child;
  }

  /// Gets called every time the transform changes.
  /// The default implementation returns a [ListenableBuilder] that listens to
  /// the [rebuildNotifier] and rebuilds the scrollbars and the transform, but
  /// not the child.
  ///
  /// Instead of overriding this method, consider overriding
  /// [buildAroundTransformAndScrollbar].
  @override
  Widget buildTransformAndScrollbars(BuildContext context, Widget child) {
    return ListenableBuilder(
      listenable: rebuildNotifier,
      builder: (context, c) {
        return buildAroundTransformAndScrollbar(
          context,
          TransformAndScrollbarsWidget(
            scrollbarController: scrollbarController,
            transform: transformForRender,
            onResize: () => Future.microtask(afterResize),
            overrideSize: overrideSize,
            child: child,
          ),
        );
      },
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
    rebuildNotifier.notify();
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

class RebuildNotifier with ChangeNotifier {
  void notify() {
    notifyListeners();
  }
}
