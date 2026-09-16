import 'package:flutter/material.dart';

// Breakpoint constants live in adaptive_layout.dart (AppBreakpoints).

/// Constrains [child] to a maximum width and centres it horizontally.
/// Useful for wrapping desktop-wide content so it doesn't stretch on very
/// large monitors.
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = 1200,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
