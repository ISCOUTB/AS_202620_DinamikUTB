import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:frontend/core/responsive/breakpoints.dart';

/// Lista desplazable centrada con márgenes adaptativos.
class PageList extends StatelessWidget {
  const PageList({super.key, required this.children, this.maxWidth = 1100});

  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final base = constraints.maxWidth >= Breakpoints.medium ? 24.0 : 16.0;
        final horizontal = math.max(base, (constraints.maxWidth - maxWidth) / 2);
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: 20),
          children: children,
        );
      },
    );
  }
}
