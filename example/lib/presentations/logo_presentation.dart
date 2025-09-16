import 'package:flutter/material.dart';
import 'package:interactive_viewer_2/interactive_viewer_2.dart';

class LogoPresentation extends StatelessWidget {
  const LogoPresentation({
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

  @override
  Widget build(BuildContext context) {
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
        child: FlutterLogo(size: 300),
    );
  }
}

