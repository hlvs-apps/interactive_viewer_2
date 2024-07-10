import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'scrollbar_painter.dart';

import 'transform_scrollbar_controller.dart';
import 'material_transform_scrollbar.dart';
import 'cupertino_transform_scrollbar.dart';

class ScrollbarControllerEncapsulation extends BaseTransformScrollbarController
    implements ExtendedTransformScrollbarControllerFunctionality {
  final RawTransformScrollbarController realController;

  ScrollbarControllerEncapsulation({
    required this.realController,
  }) {
    realController.addListener(onRealControllerNotification);
  }

  void onRealControllerNotification() {
    notifyListeners();
  }

  @override
  void dispose() {
    realController.dispose();
    super.dispose();
  }

  @override
  PublicScrollbarPainter get horizontalScrollbar =>
      realController.horizontalScrollbar;

  @override
  PublicScrollbarPainter get verticalScrollbar =>
      realController.verticalScrollbar;

  @override
  void paint(PaintingContext context, Size viewport, {Offset? origin}) {
    realController.paint(context, viewport, origin: origin);
  }

  @override
  void update(Matrix4 transform, Size viewport, Size content) {
    realController.update(transform, viewport, content);
  }

  @override
  void onScrollStart() {
    realController.onScrollStart();
  }

  @override
  void onScrollStartHorizontal() {
    realController.onScrollStartHorizontal();
  }

  @override
  void onScrollStartVertical() {
    realController.onScrollStartVertical();
  }

  @override
  void onScrollEnd() {
    realController.onScrollEnd();
  }

  @override
  void onDidChangeDependencies() {
    realController.onDidChangeDependencies();
  }

  @override
  void updateScrollbarPainters() {
    realController.updateScrollbarPainters();
  }

  @override
  Map<Type, GestureRecognizerFactory> getGesturesVertical(
      BuildContext context) {
    return realController.getGesturesVertical(context);
  }

  @override
  Map<Type, GestureRecognizerFactory> getGesturesHorizontal(
      BuildContext context) {
    return realController.getGesturesHorizontal(context);
  }

  @override
  bool get enableGestures => realController.enableGestures;

  @override
  void handleHoverExit(PointerExitEvent event) {
    realController.handleHoverExit(event);
  }

  @override
  void handleHover(PointerHoverEvent event) {
    realController.handleHover(event);
  }
}

class AutoPlatformScrollbarController extends ScrollbarControllerEncapsulation {
  AutoPlatformScrollbarController({
    required TickerProvider vsync,
    required TransformScrollbarWidgetInterface controlInterface,
    double? thickness,
    Radius? radius,
    bool? trackVisibility,
    bool? interactive,
    bool? thumbVisibility,
  }) : super(
          realController: getPlatformScrollbarController(
            vsync: vsync,
            controlInterface: controlInterface,
            thickness: thickness,
            radius: radius,
            trackVisibility: trackVisibility,
            interactive: interactive,
            thumbVisibility: thumbVisibility,
          ),
        );
}

RawTransformScrollbarController getPlatformScrollbarController({
  required TickerProvider vsync,
  required TransformScrollbarWidgetInterface controlInterface,
  double? thickness,
  Radius? radius,
  bool? trackVisibility,
  bool? interactive,
  bool? thumbVisibility,
}) {
  BuildContext context = controlInterface.getContext();
  if (Theme.of(context).platform == TargetPlatform.iOS ||
      Theme.of(context).platform == TargetPlatform.macOS) {
    return CupertinoScrollbarTransformController(
      vsync: vsync,
      controlInterface: controlInterface,
      thumbVisibility: thumbVisibility ?? false,
      thickness:
          thickness ?? CupertinoScrollbarTransformController.defaultThickness,
      thicknessWhileDragging: thickness ??
          CupertinoScrollbarTransformController.defaultThicknessWhileDragging,
      radius: radius ?? CupertinoScrollbarTransformController.defaultRadius,
      radiusWhileDragging: radius ??
          CupertinoScrollbarTransformController.defaultRadiusWhileDragging,
    );
  } else {
    return MaterialScrollbarTransformController(
      vsync: vsync,
      controlInterface: controlInterface,
      thumbVisibility: thumbVisibility,
      trackVisibility: trackVisibility,
      thickness: thickness,
      radius: radius,
      interactive: interactive,
    );
  }
}
