import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:interactive_viewer_2/interactive_viewer_2.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: HomePage());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final controller = InteractiveViewer2Controller();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CallbackShortcuts(
        bindings: {
          // Zooming
          const SingleActivator(LogicalKeyboardKey.equal): zoomIn,
          const SingleActivator(LogicalKeyboardKey.minus): zoomOut,
          // Panning
          const SingleActivator(LogicalKeyboardKey.arrowUp): panUp,
          const SingleActivator(LogicalKeyboardKey.arrowDown): panDown,
          const SingleActivator(LogicalKeyboardKey.arrowLeft): panLeft,
          const SingleActivator(LogicalKeyboardKey.arrowRight): panRight,
        },
        child: Focus(
          autofocus: true,
          child: Stack(
            children: [
              InteractiveViewer2(
                controller: controller,
                maxScale: 1.5,
                minScale: 0.5,
                child: FlutterLogo(size: 1000),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(onPressed: zoomIn, icon: Icon(Icons.zoom_in)),
                    IconButton(onPressed: zoomOut, icon: Icon(Icons.zoom_out)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void zoomIn() => controller.zoomIn(1.1);
  void zoomOut() => controller.zoomOut(0.9);

  void panUp() => controller.pan(const Offset(0, 10));
  void panDown() => controller.pan(const Offset(0, -10));
  void panLeft() => controller.pan(const Offset(10, 0));
  void panRight() => controller.pan(const Offset(-10, 0));
}
