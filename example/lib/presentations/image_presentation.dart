import 'package:flutter/material.dart';
import 'package:interactive_viewer_2/interactive_viewer_2.dart';

class ImagePresentation extends StatelessWidget {
  const ImagePresentation({
    super.key,
    required this.transformationController,
    required this.allowNonCovering,
    required this.panAxis,
    required this.panEnabled,
    required this.scaleEnabled,
    required this.showScrollbars,
    required this.noMouseDragScroll,
    required this.scaleFactor,
    required this.minScale,
    required this.maxScale,
    required this.doubleTapToZoom,
    required this.hAlign,
    required this.vAlign,
    required this.doubleTapBehaviour,
    required this.constrained,
    required this.useStandardViewer,
  });

  final TransformationController transformationController;
  final bool allowNonCovering;
  final PanAxis panAxis;
  final bool panEnabled;
  final bool scaleEnabled;
  final bool showScrollbars;
  final bool noMouseDragScroll;
  final double scaleFactor;
  final double minScale;
  final double maxScale;
  final bool doubleTapToZoom;
  final HorizontalNonCoveringZoomAlign hAlign;
  final VerticalNonCoveringZoomAlign vAlign;
  final DoubleTapZoomOutBehaviour doubleTapBehaviour;
  final bool constrained;
  final bool useStandardViewer;

  @override
  Widget build(BuildContext context) {
    final child = Image.asset(
      "assets/owl-2.jpg",
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) => const Text(
        'Failed to load image',
        style: TextStyle(color: Colors.redAccent),
      ),
    );

    if (useStandardViewer) {
      return InteractiveViewer(
        transformationController: transformationController,
        panEnabled: panEnabled,
        scaleEnabled: scaleEnabled,
        minScale: minScale,
        maxScale: maxScale,
        panAxis: panAxis,
        clipBehavior: Clip.hardEdge,
        constrained: constrained,
        child: child,
      );
    }

    return InteractiveViewer2(
      transformationController: transformationController,
      allowNonCoveringScreenZoom: allowNonCovering,
      panAxis: panAxis,
      panEnabled: panEnabled,
      scaleEnabled: scaleEnabled,
      showScrollbars: showScrollbars,
      noMouseDragScroll: noMouseDragScroll,
      scaleFactor: scaleFactor,
      minScale: minScale,
      maxScale: maxScale,
      doubleTapToZoom: doubleTapToZoom,
      nonCoveringZoomAlignmentHorizontal: hAlign,
      nonCoveringZoomAlignmentVertical: vAlign,
      doubleTapZoomOutBehaviour: doubleTapBehaviour,
      clipBehavior: Clip.hardEdge,
      constrained: constrained,
      child: child,
    );
  }
}
