import 'package:flutter/material.dart';
import 'package:interactive_viewer_2/interactive_viewer_2.dart';
import 'presentations/grid_presentation.dart' as grid_demo;
import 'presentations/logo_presentation.dart' as logo_demo;
import 'presentations/image_presentation.dart' as image_demo;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'InteractiveViewer2 Showcase',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
      home: const ViewerDemoPage(),
    );
  }
}

enum PresentationMode { grid, logo, image }

class ViewerDemoPage extends StatefulWidget {
  const ViewerDemoPage({super.key});

  @override
  State<ViewerDemoPage> createState() => _ViewerDemoPageState();
}

class _ViewerDemoPageState extends State<ViewerDemoPage> {
  final TransformationController _tc = TransformationController();

  bool _showScrollbars = true;
  bool _allowNonCovering = true;
  bool _panEnabled = true;
  bool _scaleEnabled = true;
  bool _doubleTapToZoom = true;
  bool _noMouseDragScroll = true;
  bool _constrained = false;

  double _minScale = 0.2;
  double _maxScale = 3.0;
  double _scaleFactor = 200.0;

  PanAxis _panAxis = PanAxis.free;
  HorizontalNonCoveringZoomAlign _hAlign = HorizontalNonCoveringZoomAlign.middle;
  VerticalNonCoveringZoomAlign _vAlign = VerticalNonCoveringZoomAlign.middle;
  DoubleTapZoomOutBehaviour _doubleTapBehaviour = DoubleTapZoomOutBehaviour.zoomOutToMinScale;

  PresentationMode _mode = PresentationMode.grid; // default

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _tc.value = Matrix4.identity();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('InteractiveViewer2 Showcase'),
        actions: [
          IconButton(
            tooltip: 'Reset',
            onPressed: _reset,
            icon: const Icon(Icons.restore),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final Size viewport = Size(constraints.maxWidth - 320, constraints.maxHeight);
          final m = _tc.value.storage;
          final double approxScale = m[0];

          return Row(
            children: [
              SizedBox(
                width: 320,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('Scale: ${approxScale.toStringAsFixed(2)}'),
                      Text('Viewport: ${viewport.width.toStringAsFixed(0)} x ${viewport.height.toStringAsFixed(0)}'),
                      const Divider(height: 24),

                      Text('Actions', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _reset,
                            icon: const Icon(Icons.restore),
                            label: const Text('Reset'),
                          ),
                        ],
                      ),

                      const Divider(height: 24),
                      Text('Presentation', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      DropdownButton<PresentationMode>(
                        value: _mode,
                        isExpanded: true,
                        onChanged: (v) => setState(() => _mode = v ?? PresentationMode.grid),
                        items: const [
                          DropdownMenuItem(value: PresentationMode.grid, child: Text('Grid')),
                          DropdownMenuItem(value: PresentationMode.logo, child: Text('Logo')),
                          DropdownMenuItem(value: PresentationMode.image, child: Text('Image')),
                        ],
                      ),

                      const Divider(height: 24),
                      Text('Options', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      _boolTile(
                        title: 'Show scrollbars',
                        value: _showScrollbars,
                        onChanged: (v) => setState(() => _showScrollbars = v),
                      ),
                      _boolTile(
                        title: 'Allow non-covering zoom',
                        value: _allowNonCovering,
                        onChanged: (v) => setState(() => _allowNonCovering = v),
                      ),
                      _boolTile(
                        title: 'Pan enabled',
                        value: _panEnabled,
                        onChanged: (v) => setState(() => _panEnabled = v),
                      ),
                      _boolTile(
                        title: 'Scale enabled',
                        value: _scaleEnabled,
                        onChanged: (v) => setState(() => _scaleEnabled = v),
                      ),
                      _boolTile(
                        title: 'Double-tap to zoom',
                        value: _doubleTapToZoom,
                        onChanged: (v) => setState(() => _doubleTapToZoom = v),
                      ),
                      _boolTile(
                        title: 'Disable mouse drag scroll',
                        subtitle: 'When off, you can drag with the mouse',
                        value: _noMouseDragScroll,
                        onChanged: (v) => setState(() => _noMouseDragScroll = v),
                      ),
                      _boolTile(
                        title: 'Constrained',
                        subtitle: 'Apply parent constraints to child',
                        value: _constrained,
                        onChanged: (v) => setState(() => _constrained = v),
                      ),

                      const SizedBox(height: 12),
                      Text('Pan axis'),
                      DropdownButton<PanAxis>(
                        value: _panAxis,
                        isExpanded: true,
                        onChanged: (v) => setState(() => _panAxis = v ?? PanAxis.free),
                        items: const [
                          DropdownMenuItem(value: PanAxis.free, child: Text('free')),
                          DropdownMenuItem(value: PanAxis.horizontal, child: Text('horizontal')),
                          DropdownMenuItem(value: PanAxis.vertical, child: Text('vertical')),
                          DropdownMenuItem(value: PanAxis.aligned, child: Text('aligned')),
                        ],
                      ),

                      const SizedBox(height: 12),
                      Text('Double-tap zoom-out'),
                      DropdownButton<DoubleTapZoomOutBehaviour>(
                        value: _doubleTapBehaviour,
                        isExpanded: true,
                        onChanged: (v) => setState(() => _doubleTapBehaviour = v ?? DoubleTapZoomOutBehaviour.zoomOutToMinScale),
                        items: const [
                          DropdownMenuItem(
                            value: DoubleTapZoomOutBehaviour.zoomOutToMinScale,
                            child: Text('to min scale (fit all)'),
                          ),
                          DropdownMenuItem(
                            value: DoubleTapZoomOutBehaviour.zoomOutToMatchWidth,
                            child: Text('fit width'),
                          ),
                          DropdownMenuItem(
                            value: DoubleTapZoomOutBehaviour.zoomOutToMatchHeight,
                            child: Text('fit height'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      Text('Alignment (when content is smaller than viewport)'),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Horizontal'),
                                DropdownButton<HorizontalNonCoveringZoomAlign>(
                                  value: _hAlign,
                                  isExpanded: true,
                                  onChanged: (v) => setState(() => _hAlign = v ?? HorizontalNonCoveringZoomAlign.middle),
                                  items: const [
                                    DropdownMenuItem(value: HorizontalNonCoveringZoomAlign.left, child: Text('left')),
                                    DropdownMenuItem(value: HorizontalNonCoveringZoomAlign.middle, child: Text('center')),
                                    DropdownMenuItem(value: HorizontalNonCoveringZoomAlign.right, child: Text('right')),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Vertical'),
                                DropdownButton<VerticalNonCoveringZoomAlign>(
                                  value: _vAlign,
                                  isExpanded: true,
                                  onChanged: (v) => setState(() => _vAlign = v ?? VerticalNonCoveringZoomAlign.middle),
                                  items: const [
                                    DropdownMenuItem(value: VerticalNonCoveringZoomAlign.top, child: Text('top')),
                                    DropdownMenuItem(value: VerticalNonCoveringZoomAlign.middle, child: Text('center')),
                                    DropdownMenuItem(value: VerticalNonCoveringZoomAlign.bottom, child: Text('bottom')),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      Text('Min/Max scale'),
                      Row(
                        children: [
                          Expanded(
                            child: _numberField(
                              label: 'min',
                              value: _minScale,
                              onChanged: (v) {
                                final d = double.tryParse(v) ?? _minScale;
                                setState(() {
                                  _minScale = d.clamp(0.05, 10.0);
                                  if (_maxScale < _minScale) _maxScale = _minScale;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _numberField(
                              label: 'max',
                              value: _maxScale,
                              onChanged: (v) {
                                final d = double.tryParse(v) ?? _maxScale;
                                setState(() {
                                  _maxScale = d.clamp(0.1, 20.0);
                                  if (_minScale > _maxScale) _minScale = _maxScale;
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      Text('Mouse/Trackpad scale factor (${_scaleFactor.toStringAsFixed(0)})'),
                      Slider(
                        min: 50,
                        max: 600,
                        divisions: 11,
                        value: _scaleFactor,
                        onChanged: (v) => setState(() => _scaleFactor = v),
                      ),
                    ],
                  ),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: Center(
                    child: Builder(
                      builder: (_) {
                        switch (_mode) {
                          case PresentationMode.grid:
                            return grid_demo.GridPresentation(
                              viewport: viewport,
                              transformationController: _tc,
                              allowNonCovering: _allowNonCovering,
                              panAxis: _panAxis,
                              panEnabled: _panEnabled,
                              scaleEnabled: _scaleEnabled,
                              showScrollbars: _showScrollbars,
                              noMouseDragScroll: _noMouseDragScroll,
                              scaleFactor: _scaleFactor,
                              minScale: _minScale,
                              maxScale: _maxScale,
                              doubleTapToZoom: _doubleTapToZoom,
                              hAlign: _hAlign,
                              vAlign: _vAlign,
                              doubleTapBehaviour: _doubleTapBehaviour,
                              constrained: _constrained,
                            );
                          case PresentationMode.logo:
                            return logo_demo.LogoPresentation(
                              transformationController: _tc,
                              allowNonCovering: _allowNonCovering,
                              panAxis: _panAxis,
                              panEnabled: _panEnabled,
                              scaleEnabled: _scaleEnabled,
                              showScrollbars: _showScrollbars,
                              noMouseDragScroll: _noMouseDragScroll,
                              scaleFactor: _scaleFactor,
                              minScale: _minScale,
                              maxScale: _maxScale,
                              doubleTapToZoom: _doubleTapToZoom,
                              hAlign: _hAlign,
                              vAlign: _vAlign,
                              doubleTapBehaviour: _doubleTapBehaviour,
                              constrained: _constrained,
                            );
                          case PresentationMode.image:
                            return image_demo.ImagePresentation(
                              transformationController: _tc,
                              allowNonCovering: _allowNonCovering,
                              panAxis: _panAxis,
                              panEnabled: _panEnabled,
                              scaleEnabled: _scaleEnabled,
                              showScrollbars: _showScrollbars,
                              noMouseDragScroll: _noMouseDragScroll,
                              scaleFactor: _scaleFactor,
                              minScale: _minScale,
                              maxScale: _maxScale,
                              doubleTapToZoom: _doubleTapToZoom,
                              hAlign: _hAlign,
                              vAlign: _vAlign,
                              doubleTapBehaviour: _doubleTapBehaviour,
                              constrained: _constrained,
                            );
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _boolTile({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _numberField({
    required String label,
    required double value,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      controller: TextEditingController(text: value.toStringAsFixed(2)),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onSubmitted: onChanged,
    );
  }
}
