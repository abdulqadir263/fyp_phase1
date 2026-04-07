import 'package:flutter/material.dart';

/// Lightweight responsive helper for Android screen sizes.
/// No external packages needed — uses MediaQuery only.
///
/// Usage:
///   final r = ResponsiveHelper.of(context);
///   Padding(padding: EdgeInsets.all(r.padding))
///   Text('Hello', style: TextStyle(fontSize: r.fontSize(16)))
class ResponsiveHelper {
  final BuildContext context;
  late final Size _size;
  late final double _width;
  late final double _height;
  late final DeviceType deviceType;
  late final double _scaleFactor;

  ResponsiveHelper.of(this.context) {
    _size = MediaQuery.sizeOf(context);
    _width = _size.width;
    _height = _size.height;
    deviceType = _getDeviceType();
    _scaleFactor = _getScaleFactor();
  }

  // ─── Device classification ───
  double get screenWidth => _width;
  double get screenHeight => _height;

  bool get isSmallPhone => _width <= 360;
  bool get isPhone => _width > 360 && _width <= 400;
  bool get isLargePhone => _width > 400 && _width <= 600;
  bool get isTablet => _width > 600;

  DeviceType _getDeviceType() {
    if (_width <= 360) return DeviceType.smallPhone;
    if (_width <= 400) return DeviceType.phone;
    if (_width <= 600) return DeviceType.largePhone;
    return DeviceType.tablet;
  }

  // ─── Scale factor (clamped to avoid extreme scaling) ───
  double _getScaleFactor() {
    // Base reference width: 390 (standard phone)
    final factor = _width / 390;
    return factor.clamp(0.85, 1.3);
  }

  // ─── Scaled values ───

  /// Scale a font size proportionally to screen width (clamped).
  double fontSize(double base) =>
      (base * _scaleFactor).clamp(base * 0.8, base * 1.25);

  /// Scale an icon size proportionally.
  double iconSize(double base) =>
      (base * _scaleFactor).clamp(base * 0.8, base * 1.3);

  /// Scale a spacing/padding/margin value.
  double scale(double base) =>
      (base * _scaleFactor).clamp(base * 0.7, base * 1.4);

  /// Standard page padding (horizontal + vertical).
  double get padding {
    switch (deviceType) {
      case DeviceType.smallPhone:
        return 12;
      case DeviceType.phone:
        return 16;
      case DeviceType.largePhone:
        return 18;
      case DeviceType.tablet:
        return 24;
    }
  }

  /// Standard horizontal page padding.
  double get hPadding => padding;

  /// Standard vertical spacing between sections.
  double get sectionSpacing {
    switch (deviceType) {
      case DeviceType.smallPhone:
        return 16;
      case DeviceType.phone:
        return 20;
      case DeviceType.largePhone:
        return 24;
      case DeviceType.tablet:
        return 28;
    }
  }

  // ─── Grid helpers ───

  /// Calculate optimal grid cross axis count based on available width
  /// and minimum item width.
  int gridCrossAxisCount({double minItemWidth = 160}) {
    final count = (_width / minItemWidth).floor();
    return count.clamp(1, 6);
  }

  /// Adaptive child aspect ratio for product grids.
  double get productGridAspectRatio {
    if (isSmallPhone) return 0.62;
    if (isPhone) return 0.65;
    if (isLargePhone) return 0.68;
    return 0.72; // tablet
  }

  /// Max content width for centering on tablets.
  static const double maxContentWidth = 800;

  // ─── Static convenience methods ───

  /// Wrap content with tablet-safe centering.
  /// On phones, returns child as-is. On tablets, centers with max width.
  static Widget tabletCenter({
    required Widget child,
    double maxWidth = maxContentWidth,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          );
        }
        return child;
      },
    );
  }

  /// Quick shortcut to get responsive grid delegate.
  static SliverGridDelegateWithFixedCrossAxisCount responsiveGrid(
    BuildContext context, {
    double minItemWidth = 160,
    double childAspectRatio = 0.68,
    double spacing = 12,
  }) {
    final r = ResponsiveHelper.of(context);
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: r.gridCrossAxisCount(minItemWidth: minItemWidth),
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: r.scale(spacing),
      mainAxisSpacing: r.scale(spacing),
    );
  }
}

/// Device type classification for Android screen sizes.
enum DeviceType {
  smallPhone, // <= 360dp width
  phone, // 361-400dp
  largePhone, // 401-600dp
  tablet, // > 600dp
}
