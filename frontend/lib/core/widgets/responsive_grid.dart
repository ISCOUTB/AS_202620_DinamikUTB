import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Ajusta el número de columnas al ancho disponible.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minTileWidth = 280,
    this.spacing = 16,
  });

  final List<Widget> children;
  final double minTileWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnas = math.max(
          1,
          ((constraints.maxWidth + spacing) / (minTileWidth + spacing)).floor(),
        );
        final ancho = (constraints.maxWidth - spacing * (columnas - 1)) / columnas;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final hijo in children) SizedBox(width: ancho, child: hijo),
          ],
        );
      },
    );
  }
}
