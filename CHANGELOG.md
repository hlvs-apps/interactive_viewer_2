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
