library interactive_viewer_2;

import 'package:flutter/material.dart';

import 'better_interactive_viewer.dart';

/// A drop in replacement for the InteractiveViewer widget with better zoom support, scrollbars, and more.
class InteractiveViewer2 extends BetterInteractiveViewer {
  /// The child contained by the InteractiveViewer.
  final Widget child;

  InteractiveViewer2({
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
    super.nonCoveringZoomAlignmentHorizontal,
    super.nonCoveringZoomAlignmentVertical,
    super.doubleTapZoomOutBehaviour,
    super.clipBehavior = Clip.hardEdge,
    required this.child,
  });

  @override
  BetterInteractiveViewerState<InteractiveViewer2> createState() =>
      _InteractiveViewer2State();
}

class _InteractiveViewer2State
    extends BetterInteractiveViewerState<InteractiveViewer2> {
  @override
  Widget buildUnKeyedChild(BuildContext context) {
    return widget.child;
  }

  @override
  Size? get overrideSize => null;
}
