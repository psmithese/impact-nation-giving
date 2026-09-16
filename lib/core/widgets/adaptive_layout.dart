import 'package:flutter/material.dart';

/// Screen-size breakpoints for the Impact Nation admin panel.
class AppBreakpoints {
  AppBreakpoints._();

  /// Width at which layout switches from mobile to desktop.
  static const double desktop = 900;

  /// Width at which layout switches from mobile to tablet.
  static const double tablet = 600;

  /// Returns true when the current screen width is desktop-sized (≥ 900 px).
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktop;

  /// Returns true when the current screen width is at least tablet-sized (≥ 600 px).
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= tablet;
}

/// Renders [desktopChild] on screens ≥ [AppBreakpoints.desktop],
/// otherwise renders [mobileChild].
class AdaptiveLayout extends StatelessWidget {
  final Widget mobileChild;
  final Widget desktopChild;

  const AdaptiveLayout({
    super.key,
    required this.mobileChild,
    required this.desktopChild,
  });

  @override
  Widget build(BuildContext context) {
    return AppBreakpoints.isDesktop(context) ? desktopChild : mobileChild;
  }
}
