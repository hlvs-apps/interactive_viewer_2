# Interactive Viewer 2

[![Pub Version](https://img.shields.io/pub/v/interactive_viewer_2.svg)](https://pub.dev/packages/interactive_viewer_2)

**Interactive Viewer 2** is a Flutter library that offers enhanced functionalities compared to the default `InteractiveViewer`. It provides smoother interaction, improved zoom features, and better support for widgets larger than the viewport. If you're looking to implement interactive and zoomable widgets in your Flutter app, this package is designed to fulfill those needs.

## Features

- **Mouse Wheel Zoom:** Enables zooming using the mouse wheel, providing a more intuitive experience for desktop users.
- **Scrollbars:** Adds scrollbar support for easier navigation within the interactive viewer.
- **Double Tap Zoom:** Supports double tap gestures for zooming in and out, enhancing usability on touch-based devices.
- **Better Widget Support:** Provides improved handling for widgets that exceed the viewport size, ensuring a seamless user experience.
- **Own Interactive Widgets:** Allows you to create your own interactive widgets by extending the `BetterInteractiveViewer` or `BetterInteractiveViewerBase` classes, with all the enhanced zoom and scroll functionalities IneractiveViewer2 offers.

## Getting Started

1. **Installation**: Install the package according to the [installation](https://pub.dev/packages/interactive_viewer_2/install) page.
### InteractiveViewer2
- **Import:** Import the package in your Dart code:

    ```dart
    import 'package:interactive_viewer_2/interactive_viewer_2.dart';
    ```

- **Usage:** Replace usages of the default `InteractiveViewer` with `InteractiveViewer2` to utilize the enhanced features:

    ```dart
    InteractiveViewer2(
      // Add your child widget here
      child: YourWidget(),
    )
    ```
  
### Own Interactive Widgets
- **Import:** Import the package in your Dart code:

    ```dart
    import 'package:interactive_viewer_2/interactive_dev.dart';
    ```
  
- **Usage:** Extend the `BetterInteractiveViewer` or `BetterInteractiveViewerBase` and the matching state class to create your own interactive widgets:

    ```dart
    class MyInteractiveWidget extends BetterInteractiveViewer {
      // Implement your custom interactive widget here
    }
  
    class MyInteractiveWidgetState extends BetterInteractiveViewerState<MyInteractiveWidget> {
      // Implement the state of your custom interactive widget here
    }
    ```

  
- **Example:** The [InteractiveTable](https://pub.dev/packages/interactive_table) package uses this feature to create an interactive table widget designed as a drop-in replacement for Flutter's `DataTable` with all the zoom and scroll functionalities of `InteractiveViewer2`.

<!--For more detailed examples and API documentation, refer to the [API Documentation](https://pub.dev/documentation/interactive_viewer_2/latest/).-->

## Contributions and Issues

Contributions, bug reports, and feature requests are welcome! Please feel free to [open an issue](https://github.com/hlvs-apps/interactive_viewer_2/issues) or [create a pull request](https://github.com/hlvs-apps/interactive_viewer_2/pulls) on GitHub.

## License

This project is licensed under the BSD 3-Clause License. See the [LICENSE](https://github.com/hlvs-apps/interactive_viewer_2/blob/main/LICENSE) file for details.
