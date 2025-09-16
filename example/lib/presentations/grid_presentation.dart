import 'package:flutter/material.dart';
import 'package:interactive_viewer_2/interactive_viewer_2.dart';

class GridPresentation extends StatelessWidget {
  const GridPresentation({
    super.key,
    required this.viewport,
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

  final Size viewport;
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

  static const Size _contentSize = Size(3000, 2000);

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
      child: SizedBox(
        width: _contentSize.width,
        height: _contentSize.height,
        child: CustomPaint(
          painter: _GridPainter(),
          child: const Center(
            child: DecoratedBox(
              decoration: BoxDecoration(color: Colors.black12),
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Zoom & Pan\n(Double-tap to zoom, use mouse wheel with Ctrl to zoom)',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint pThin = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;
    final Paint pBold = Paint()
      ..color = Colors.grey.shade500
      ..strokeWidth = 2;

    double bigStep = 500;
    double step = bigStep / 5;

    for (double x = 0; x <= size.width; x += step) {
      final paint = (x % bigStep == 0) ? pBold : pThin;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      final paint = (y % bigStep == 0) ? pBold : pThin;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (double x = 0; x <= size.width; x += bigStep) {
      for (double y = 0; y <= size.height; y += bigStep) {
        final rect = Rect.fromLTWH(x, y, bigStep, bigStep);
        textPainter.text = TextSpan(
          text: '${x.toInt()},${y.toInt()}',
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        );
        textPainter.layout();
        textPainter.paint(canvas, rect.topLeft + const Offset(6, 6));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
