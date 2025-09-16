//Copied from RenderTransform in flutter source code

import 'package:flutter/rendering.dart';
import 'transform_scrollbar_controller.dart';

/// Applies a transformation before painting its child.
class RenderTransformAndScrollbarsWidget extends RenderProxyBox {
  /// Creates a render object that transforms its child.
  RenderTransformAndScrollbarsWidget({
    required Matrix4 transform,
    Offset? origin,
    AlignmentGeometry? alignment,
    TextDirection? textDirection,
    this.transformHitTests = true,
    RenderBox? child,
    BaseTransformScrollbarController? scrollbarController,
    Function()? onResize,
    Size? overrideSize,
    bool constrained = false,
  }) : super(child) {
    this.transform = transform;
    this.alignment = alignment;
    this.textDirection = textDirection;
    this.origin = origin;
    this.onResize = onResize;
    this.scrollbarController = scrollbarController;
    this.overrideSize = overrideSize;
    this.constrained = constrained;
  }

  /// The origin of the coordinate system (relative to the upper left corner of
  /// this render object) in which to apply the matrix.
  ///
  /// Setting an origin is equivalent to conjugating the transform matrix by a
  /// translation. This property is provided just for convenience.
  Offset? get origin => _origin;
  Offset? _origin;

  set origin(Offset? value) {
    if (_origin == value) {
      return;
    }
    _origin = value;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  Size? get overrideSize => _overrideSize;
  Size? _overrideSize;

  set overrideSize(Size? value) {
    if (_overrideSize == value) {
      return;
    }
    _overrideSize = value;
    markNeedsLayout();
  }

  bool get constrained => _constrained;
  bool _constrained = false;

  set constrained(bool value) {
    if (_constrained == value) {
      return;
    }
    _constrained = value;
    markNeedsLayout();
  }

  /// The alignment of the origin, relative to the size of the box.
  ///
  /// This is equivalent to setting an origin based on the size of the box.
  /// If it is specified at the same time as an offset, both are applied.
  ///
  /// An [AlignmentDirectional.centerStart] value is the same as an [Alignment]
  /// whose [Alignment.x] value is `-1.0` if [textDirection] is
  /// [TextDirection.ltr], and `1.0` if [textDirection] is [TextDirection.rtl].
  /// Similarly [AlignmentDirectional.centerEnd] is the same as an [Alignment]
  /// whose [Alignment.x] value is `1.0` if [textDirection] is
  /// [TextDirection.ltr], and `-1.0` if [textDirection] is [TextDirection.rtl].
  AlignmentGeometry? get alignment => _alignment;
  AlignmentGeometry? _alignment;

  set alignment(AlignmentGeometry? value) {
    if (_alignment == value) {
      return;
    }
    _alignment = value;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  /// The text direction with which to resolve [alignment].
  ///
  /// This may be changed to null, but only after [alignment] has been changed
  /// to a value that does not depend on the direction.
  TextDirection? get textDirection => _textDirection;
  TextDirection? _textDirection;

  set textDirection(TextDirection? value) {
    if (_textDirection == value) {
      return;
    }
    _textDirection = value;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  @override
  bool get alwaysNeedsCompositing => false;

  /// When set to true, hit tests are performed based on the position of the
  /// child as it is painted. When set to false, hit tests are performed
  /// ignoring the transformation.
  ///
  /// [applyPaintTransform], and therefore [localToGlobal] and [globalToLocal],
  /// always honor the transformation, regardless of the value of this property.
  bool transformHitTests;

  Matrix4? _transform;

  /// The matrix to transform the child by during painting. The provided value
  /// is copied on assignment.
  ///
  /// There is no getter for [transform], because [Matrix4] is mutable, and
  /// mutations outside of the control of the render object could not reliably
  /// be reflected in the rendering.
  set transform(Matrix4 value) {
    // ignore: avoid_setters_without_getters
    if (_transform == value) {
      return;
    }
    _transform = Matrix4.copy(value);
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  BaseTransformScrollbarController? get scrollbarController =>
      _scrollbarController;
  BaseTransformScrollbarController? _scrollbarController;

  set scrollbarController(BaseTransformScrollbarController? value) {
    if (_scrollbarController == value) {
      return;
    }
    _scrollbarController?.removeListener(_onScrollbarControllerScrollChanged);
    _scrollbarController = value;
    _scrollbarController?.addListener(_onScrollbarControllerScrollChanged);
  }

  void _onScrollbarControllerScrollChanged() {
    markNeedsPaint();
  }

  Function()? get onResize => _onResize;
  Function()? _onResize;

  set onResize(Function()? value) {
    if (_onResize == value) {
      return;
    }
    _onResize = value;
  }

  Size? _lastSize;
  @override
  void performLayout() {
    Size s = this.constraints.biggest;
    BoxConstraints constraints =
        constrained ? this.constraints : const BoxConstraints();
    if (_overrideSize != null) {
      constraints = BoxConstraints.tight(_overrideSize!);
    }
    child?.layout(constraints);
    size = s;
    if (_lastSize != s) {
      _lastSize = s;
      onResize?.call();
    }
  }

  @override
  void markNeedsPaint() {
    if (_painting) {
      return;
    }
    super.markNeedsPaint();
  }

  bool _painting = false;

  Matrix4? get _effectiveTransform {
    final Alignment? resolvedAlignment = alignment?.resolve(textDirection);
    if (_origin == null && resolvedAlignment == null) {
      return _transform;
    }
    final Matrix4 result = Matrix4.identity();
    if (_origin != null) {
      result.translate(_origin!.dx, _origin!.dy);
    }
    Offset? translation;
    if (resolvedAlignment != null) {
      translation = resolvedAlignment.alongSize(size);
      result.translate(translation.dx, translation.dy);
    }
    result.multiply(_transform!);
    if (resolvedAlignment != null) {
      result.translate(-translation!.dx, -translation.dy);
    }
    if (_origin != null) {
      result.translate(-_origin!.dx, -_origin!.dy);
    }
    return result;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // RenderTransform objects don't check if they are
    // themselves hit, because it's confusing to think about
    // how the untransformed size and the child's transformed
    // position interact.
    return hitTestChildren(result, position: position);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    assert(!transformHitTests || _effectiveTransform != null);
    if (scrollbarController?.horizontalScrollbar.hitTest(position) ?? false) {
      return true;
    }

    if (scrollbarController?.verticalScrollbar.hitTest(position) ?? false) {
      return true;
    }

    return result.addWithPaintTransform(
      transform: transformHitTests ? _effectiveTransform : null,
      position: position,
      hitTest: (BoxHitTestResult result, Offset position) {
        return super.hitTestChildren(result, position: position);
      },
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _painting = true;
    try {
      doPaint(context, offset);
    } finally {
      _painting = false;
    }
  }

  void doPaint(PaintingContext context, Offset offset) {
    context.pushClipRect(needsCompositing, offset, Offset.zero & size,
        (context, offset) {
      if (child != null) {
        final Matrix4 transform = _effectiveTransform!;
        final Offset? childOffset = MatrixUtils.getAsTranslation(transform);
        if (childOffset == null) {
          // if the matrix is singular the children would be compressed to a line or
          // single point, instead short-circuit and paint nothing.
          final double det = transform.determinant();
          if (det == 0 || !det.isFinite) {
            layer = null;
            return;
          }
          layer = context.pushTransform(
            needsCompositing,
            offset,
            transform,
            super.paint,
            oldLayer: layer is TransformLayer ? layer as TransformLayer? : null,
          );
        } else {
          super.paint(context, offset + childOffset);
          layer = null;
        }
        _scrollbarController?.updateAndPaint(
            context, transform, size, child!.size,
            origin: offset);
      }
    });
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.multiply(_effectiveTransform!);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(TransformProperty('transform matrix', _transform));
    properties.add(DiagnosticsProperty<Offset>('origin', origin));
    properties
        .add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection,
        defaultValue: null));
    properties
        .add(DiagnosticsProperty<bool>('transformHitTests', transformHitTests));
  }

  @override
  void dispose() {
    scrollbarController?.removeListener(_onScrollbarControllerScrollChanged);
    super.dispose();
  }
}
