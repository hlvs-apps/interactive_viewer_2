library interactive_viewer_2_src;

import 'package:flutter/material.dart';

import 'transform_scrollbar_controller.dart';
import 'material_transform_scrollbar.dart';
import 'cupertino_transform_scrollbar.dart';

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
