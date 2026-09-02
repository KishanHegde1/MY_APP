import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    required this.mobile,
    required this.desktop,
    this.breakpoint = 720,
    super.key,
  });
  final Widget mobile;
  final Widget desktop;
  final double breakpoint;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, constraints) =>
        constraints.maxWidth >= breakpoint ? desktop : mobile,
  );
}
