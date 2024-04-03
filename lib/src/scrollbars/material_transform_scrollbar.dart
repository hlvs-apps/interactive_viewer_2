library interactive_viewer_2;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'scrollbar_painter.dart';

import 'transform_scrollbar_controller.dart';

//Copied from material/scollbar.dart

const double _kScrollbarThickness = 8.0;
const double _kScrollbarThicknessWithTrack = 12.0;
const double _kScrollbarMargin = 2.0;
const double _kScrollbarMinLength = 48.0;
const Radius _kScrollbarRadius = Radius.circular(8.0);
const Duration _kScrollbarFadeDuration = Duration(milliseconds: 300);
const Duration _kScrollbarTimeToFade = Duration(milliseconds: 600);

class MaterialScrollbarTransformController
    extends RawTransformScrollbarController {
  MaterialScrollbarTransformController({
    required super.vsync,
    required super.controlInterface,
    super.thumbVisibility,
    super.trackVisibility,
    this.showTrackOnHover,
    super.thickness,
    super.radius,
    super.interactive,
  })  : _hoverAnimationControllerV = AnimationController(
          vsync: vsync,
          duration: const Duration(milliseconds: 200),
        ),
        _hoverAnimationControllerH = AnimationController(
          vsync: vsync,
          duration: const Duration(milliseconds: 200),
        ),
        super(
          fadeDuration: _kScrollbarFadeDuration,
          timeToFade: _kScrollbarTimeToFade,
          pressDuration: Duration.zero,
        ) {
    _hoverAnimationControllerV.addListener(() {
      updateScrollbarPainter(true);
    });
    _hoverAnimationControllerH.addListener(() {
      updateScrollbarPainter(false);
    });
    onDidChangeDependencies();
  }

  final bool? showTrackOnHover;

  final AnimationController _hoverAnimationControllerV;
  final AnimationController _hoverAnimationControllerH;
  bool _dragIsActiveV = false;
  bool _dragIsActiveH = false;
  bool _hoverIsActiveV = false;
  bool _hoverIsActiveH = false;
  late ColorScheme _colorScheme;
  late ScrollbarThemeData _scrollbarTheme;

  // On Android, scrollbars should match native appearance.
  late bool _useAndroidScrollbar;

  @override
  bool get showScrollbarV =>
      thumbVisibility ??
      _scrollbarTheme.thumbVisibility?.resolve(_statesV) ??
      false;

  @override
  bool get showScrollbarH =>
      thumbVisibility ??
      _scrollbarTheme.thumbVisibility?.resolve(_statesH) ??
      false;

  @override
  bool get enableGestures =>
      interactive ?? _scrollbarTheme.interactive ?? !_useAndroidScrollbar;

  bool get _showTrackOnHoverV =>
      showTrackOnHover ??
      _scrollbarTheme.trackVisibility?.resolve(_statesV) ??
      false;

  bool get _showTrackOnHoverH =>
      showTrackOnHover ??
      _scrollbarTheme.trackVisibility?.resolve(_statesH) ??
      false;

  MaterialStateProperty<bool> get _trackVisibilityV =>
      MaterialStateProperty.resolveWith((Set<MaterialState> states) {
        if (states.contains(MaterialState.hovered) && _showTrackOnHoverV) {
          return true;
        }
        return trackVisibilityV ??
            _scrollbarTheme.trackVisibility?.resolve(states) ??
            false;
      });

  MaterialStateProperty<bool> get _trackVisibilityH =>
      MaterialStateProperty.resolveWith((Set<MaterialState> states) {
        if (states.contains(MaterialState.hovered) && _showTrackOnHoverH) {
          return true;
        }
        return trackVisibilityH ??
            _scrollbarTheme.trackVisibility?.resolve(states) ??
            false;
      });

  Set<MaterialState> get _statesV => <MaterialState>{
        if (_dragIsActiveV) MaterialState.dragged,
        if (_hoverIsActiveV) MaterialState.hovered,
      };

  Set<MaterialState> get _statesH => <MaterialState>{
        if (_dragIsActiveH) MaterialState.dragged,
        if (_hoverIsActiveH) MaterialState.hovered,
      };

  MaterialStateProperty<Color> getThumbColor({required bool isVertical}) {
    final Color onSurface = _colorScheme.onSurface;
    final Brightness brightness = _colorScheme.brightness;
    late Color dragColor;
    late Color hoverColor;
    late Color idleColor;
    switch (brightness) {
      case Brightness.light:
        dragColor = onSurface.withOpacity(0.6);
        hoverColor = onSurface.withOpacity(0.5);
        idleColor = _useAndroidScrollbar
            ? Theme.of(context).highlightColor.withOpacity(1.0)
            : onSurface.withOpacity(0.1);
      case Brightness.dark:
        dragColor = onSurface.withOpacity(0.75);
        hoverColor = onSurface.withOpacity(0.65);
        idleColor = _useAndroidScrollbar
            ? Theme.of(context).highlightColor.withOpacity(1.0)
            : onSurface.withOpacity(0.3);
    }

    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.dragged)) {
        return _scrollbarTheme.thumbColor?.resolve(states) ?? dragColor;
      }

      // If the track is visible, the thumb color hover animation is ignored and
      // changes immediately.
      if (_trackVisibilityH.resolve(states)) {
        return _scrollbarTheme.thumbColor?.resolve(states) ?? hoverColor;
      }

      if (isVertical) {
        return Color.lerp(
          _scrollbarTheme.thumbColor?.resolve(states) ?? idleColor,
          _scrollbarTheme.thumbColor?.resolve(states) ?? hoverColor,
          _hoverAnimationControllerV.value,
        )!;
      } else {
        return Color.lerp(
          _scrollbarTheme.thumbColor?.resolve(states) ?? idleColor,
          _scrollbarTheme.thumbColor?.resolve(states) ?? hoverColor,
          _hoverAnimationControllerH.value,
        )!;
      }
    });
  }

  MaterialStateProperty<Color> get _trackColorV {
    final Color onSurface = _colorScheme.onSurface;
    final Brightness brightness = _colorScheme.brightness;
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (showScrollbarV && _trackVisibilityV.resolve(states)) {
        return _scrollbarTheme.trackColor?.resolve(states) ??
            (brightness == Brightness.light
                ? onSurface.withOpacity(0.03)
                : onSurface.withOpacity(0.05));
      }
      return const Color(0x00000000);
    });
  }

  MaterialStateProperty<Color> get _trackColorH {
    final Color onSurface = _colorScheme.onSurface;
    final Brightness brightness = _colorScheme.brightness;
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (showScrollbarH && _trackVisibilityH.resolve(states)) {
        return _scrollbarTheme.trackColor?.resolve(states) ??
            (brightness == Brightness.light
                ? onSurface.withOpacity(0.03)
                : onSurface.withOpacity(0.05));
      }
      return const Color(0x00000000);
    });
  }

  MaterialStateProperty<Color> get _trackBorderColorV {
    final Color onSurface = _colorScheme.onSurface;
    final Brightness brightness = _colorScheme.brightness;
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (showScrollbarV && _trackVisibilityV.resolve(states)) {
        return _scrollbarTheme.trackBorderColor?.resolve(states) ??
            (brightness == Brightness.light
                ? onSurface.withOpacity(0.1)
                : onSurface.withOpacity(0.25));
      }
      return const Color(0x00000000);
    });
  }

  MaterialStateProperty<Color> get _trackBorderColorH {
    final Color onSurface = _colorScheme.onSurface;
    final Brightness brightness = _colorScheme.brightness;
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (showScrollbarH && _trackVisibilityH.resolve(states)) {
        return _scrollbarTheme.trackBorderColor?.resolve(states) ??
            (brightness == Brightness.light
                ? onSurface.withOpacity(0.1)
                : onSurface.withOpacity(0.25));
      }
      return const Color(0x00000000);
    });
  }

  MaterialStateProperty<double> get _thicknessV {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.hovered) &&
          _trackVisibilityV.resolve(states)) {
        return _scrollbarTheme.thickness?.resolve(states) ??
            _kScrollbarThicknessWithTrack;
      }
      // The default scrollbar thickness is smaller on mobile.
      return thickness ??
          _scrollbarTheme.thickness?.resolve(states) ??
          (_kScrollbarThickness / (_useAndroidScrollbar ? 2 : 1));
    });
  }

  MaterialStateProperty<double> get _thicknessH {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.hovered) &&
          _trackVisibilityH.resolve(states)) {
        return _scrollbarTheme.thickness?.resolve(states) ??
            _kScrollbarThicknessWithTrack;
      }
      // The default scrollbar thickness is smaller on mobile.
      return thickness ??
          _scrollbarTheme.thickness?.resolve(states) ??
          (_kScrollbarThickness / (_useAndroidScrollbar ? 2 : 1));
    });
  }

  @override
  void onDidChangeDependencies() {
    final ThemeData theme = Theme.of(context);
    _colorScheme = theme.colorScheme;
    _scrollbarTheme = ScrollbarTheme.of(context);
    switch (theme.platform) {
      case TargetPlatform.android:
        _useAndroidScrollbar = true;
      case TargetPlatform.iOS:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        _useAndroidScrollbar = false;
    }
  }

  @override
  void updateScrollbarPainter(bool vertical) {
    PublicScrollbarPainter scrollbarPainter =
        vertical ? verticalScrollbar : horizontalScrollbar;

    scrollbarPainter
      ..color = getThumbColor(isVertical: vertical)
          .resolve(vertical ? _statesV : _statesH)
      ..trackColor = vertical
          ? _trackColorV.resolve(_statesV)
          : _trackColorH.resolve(_statesH)
      ..trackBorderColor = vertical
          ? _trackBorderColorV.resolve(_statesV)
          : _trackBorderColorH.resolve(_statesH)
      ..textDirection = Directionality.of(context)
      ..thickness = vertical
          ? _thicknessV.resolve(_statesV)
          : _thicknessH.resolve(_statesH)
      ..radius = radius ??
          _scrollbarTheme.radius ??
          (_useAndroidScrollbar ? null : _kScrollbarRadius)
      ..crossAxisMargin = _scrollbarTheme.crossAxisMargin ??
          (_useAndroidScrollbar ? 0.0 : _kScrollbarMargin)
      ..mainAxisMargin = _scrollbarTheme.mainAxisMargin ?? 0.0
      ..minLength = _scrollbarTheme.minThumbLength ?? _kScrollbarMinLength
      ..padding = MediaQuery.paddingOf(context)
      ..ignorePointer = !enableGestures;
  }

  @override
  void handleThumbPressStartVertical(Offset position) {
    super.handleThumbPressStartVertical(position);
    _dragIsActiveV = true;
    updateScrollbarPainter(true);
  }

  @override
  void handleThumbPressStartHorizontal(Offset position) {
    super.handleThumbPressStartHorizontal(position);
    _dragIsActiveH = true;
    updateScrollbarPainter(false);
  }

  @override
  void handleThumbPressEndVertical(Offset position, Velocity velocity) {
    super.handleThumbPressEndVertical(position, velocity);
    _dragIsActiveV = false;
    updateScrollbarPainter(true);
  }

  @override
  void handleThumbPressEndHorizontal(Offset position, Velocity velocity) {
    super.handleThumbPressEndHorizontal(position, velocity);
    _dragIsActiveH = false;
    updateScrollbarPainter(false);
  }

  @override
  void handleHoverV(PointerHoverEvent event) {
    super.handleHoverV(event);
    // Check if the position of the pointer falls over the painted scrollbar
    if (isPointerOverScrollbarV(event.position, event.kind)) {
      // Pointer is hovering over the scrollbar
      _hoverIsActiveV = true;
      _hoverAnimationControllerV.forward();
    } else if (_hoverIsActiveV) {
      // Pointer was, but is no longer over painted scrollbar.
      _hoverIsActiveV = false;
      _hoverAnimationControllerV.reverse();
    }
  }

  @override
  void handleHoverH(PointerHoverEvent event) {
    super.handleHoverH(event);
    // Check if the position of the pointer falls over the painted scrollbar
    if (isPointerOverScrollbarH(event.position, event.kind)) {
      // Pointer is hovering over the scrollbar
      _hoverIsActiveH = true;
      _hoverAnimationControllerH.forward();
    } else if (_hoverIsActiveH) {
      // Pointer was, but is no longer over painted scrollbar.
      _hoverIsActiveH = false;
      _hoverAnimationControllerH.reverse();
    }
  }

  @override
  void handleHoverExitV(PointerExitEvent event) {
    super.handleHoverExitV(event);
    _hoverIsActiveV = false;
    _hoverAnimationControllerV.reverse();
  }

  @override
  void handleHoverExitH(PointerExitEvent event) {
    super.handleHoverExitH(event);
    _hoverIsActiveH = false;
    _hoverAnimationControllerH.reverse();
  }

  @override
  void dispose() {
    _hoverAnimationControllerV.dispose();
    _hoverAnimationControllerH.dispose();
    super.dispose();
  }
}
