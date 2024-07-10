## 0.0.1

* Initial release of the package.

## 0.0.2

* Allows to set the child Size in BetterInteractiveViewer

## 0.0.3

* Maybe better documentation

## 0.0.4

* Better performance while rebuilding due to transformation changes

## 0.0.5

* Bugfix: now disposing a resource correctly

## 0.0.6

* Bugfix: showing scrollbars on web correctly

## 0.0.7

* Allows to add own paint calls that depend on the transformation matrix by overriding the ScrollbarPainter
  implementation. To do so, override the "void setScrollbarControllers()" method in the
  BetterInteractiveViewerBaseState.
* This is made possible by encapsulating the "RawTransformScrollbarController getPlatformScrollbarController" method in
  auto_platform_scrollbar_controller.dart in a new class "AutoPlatformScrollbarController" that provides all the
  necessary methods needed to configure and paint the scrollbars and delegating to the platform specific scrollbar
  implementation. To add own paint calls, override the "void paint" method in the AutoPlatformScrollbarController class.

## 0.0.8

* It's now easier to add own paint calls as described in previous version:
  Now the "BetterInteractiveViewerBaseState" class provides a method "ScrollbarControllerEncapsulation
  getScrollbarController({required TickerProvider vsync,required TransformScrollbarWidgetInterface controlInterface})"
  that gets called by the "setScrollbarControllers" method. This
  allows to easily override the "AutoPlatformScrollbarController" class and provide an own implementation of the paint
  method, without the need to write an own configuration for the scrollbar controller.

## 0.0.9

* Bugfix for animation controllers disposal and better documentation

## 0.0.10

* Upgraded deprecated Code