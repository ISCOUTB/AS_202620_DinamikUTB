import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_theme.dart';

void main() {
  test('los botones principales usan el color cian institucional', () {
    final theme = AppTheme.light;

    expect(
      theme.elevatedButtonTheme.style?.backgroundColor?.resolve({}),
      AppColors.cyan,
    );
    expect(
      theme.filledButtonTheme.style?.backgroundColor?.resolve({}),
      AppColors.cyan,
    );
  });
}
