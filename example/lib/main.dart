import 'package:flutter/material.dart';
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

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: InteractiveViewer2(child: FlutterLogo(size: 1000)));
  }
}
