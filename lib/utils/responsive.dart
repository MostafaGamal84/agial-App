import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Utility helpers for building responsive UIs across different screen sizes.
///
/// The app was originally designed against mobile breakpoints. These helpers
/// allow us to scale a handful of measurements so that the layout can breathe
/// on phones while also expanding gracefully on larger devices such as
/// tablets and desktop windows.
class Responsive {
  const Responsive._();

  /// Clamps [value] between [min] and [max].
  static double clamp(double value, double min, double max) {
    assert(min <= max, 'The minimum boundary must be smaller than the maximum');
    return math.min(max, math.max(min, value));
  }

  /// Returns a width-aware scale factor based on the provided [width].
  ///
  /// [baseWidth] represents the original design width. The calculated scale is
  /// clamped between [minScale] and [maxScale] to avoid tiny or oversized UI.
  static double scaleForWidth(
    double width, {
    double baseWidth = 375,
    double minScale = 0.85,
    double maxScale = 1.35,
  }) {
    final scale = width / baseWidth;
    return clamp(scale, minScale, maxScale);
  }

  /// Returns a value scaled by the available [width].
  ///
  /// Handy when a padding, spacing or measurement should grow on tablets.
  static double scaledValue(
    double width,
    double baseValue, {
    double baseWidth = 375,
    double minScale = 0.9,
    double maxScale = 1.25,
    double? min,
    double? max,
  }) {
    final scale = scaleForWidth(
      width,
      baseWidth: baseWidth,
      minScale: minScale,
      maxScale: maxScale,
    );
    double value = baseValue * scale;
    if (min != null) {
      value = math.max(min, value);
    }
    if (max != null) {
      value = math.min(max, value);
    }
    return value;
  }

  /// Calculates a horizontal padding that keeps [maxContentWidth] centered on
  /// large displays while respecting [minPadding] on phones.
  static double horizontalPadding(
    double width, {
    double minPadding = 24,
    double maxContentWidth = 600,
  }) {
    final minTotal = minPadding * 2;
    if (width <= maxContentWidth + minTotal) {
      return minPadding;
    }
    final centered = (width - maxContentWidth) / 2;
    return math.max(minPadding, centered);
  }

  /// Provides symmetric padding that adapts to the available [width].
  static EdgeInsets symmetricPadding(
    double width, {
    double horizontal = 24,
    double vertical = 24,
    double maxContentWidth = 600,
  }) {
    final side = horizontalPadding(
      width,
      minPadding: horizontal,
      maxContentWidth: maxContentWidth,
    );
    return EdgeInsets.symmetric(horizontal: side, vertical: vertical);
  }

  /// Picks a value depending on the available [width].
  ///
  /// Useful when a widget needs to jump between a couple of discrete sizes
  /// once the screen reaches tablet breakpoints.
  static T valueForWidth<T>(
    double width, {
    required T narrow,
    required T wide,
    double breakpoint = 600,
  }) {
    return width >= breakpoint ? wide : narrow;
  }
}
