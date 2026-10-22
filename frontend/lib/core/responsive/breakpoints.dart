import 'package:flutter/widgets.dart';

enum ScreenSize { compact, medium, expanded }

/// Anchos de referencia para móvil, tableta y escritorio.
abstract final class Breakpoints {
  static const double medium = 600;
  static const double expanded = 1024;

  static ScreenSize fromWidth(double width) {
    if (width >= expanded) return ScreenSize.expanded;
    if (width >= medium) return ScreenSize.medium;
    return ScreenSize.compact;
  }

  static ScreenSize of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);
}
