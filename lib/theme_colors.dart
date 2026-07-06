import 'package:flutter/material.dart';

extension ThemeColors on BuildContext {
  Color get scaffoldBg => Theme.of(this).scaffoldBackgroundColor;
  Color get cardBg => Theme.of(this).cardColor;
  Color get primary => Theme.of(this).colorScheme.primary;
  Color get textPrimary => Theme.of(this).colorScheme.onSurface;
  Color get textMuted => Theme.of(this).colorScheme.onSurface.withValues(alpha: 0.6);
  Color get borderColor => Theme.of(this).dividerTheme.color ?? Theme.of(this).colorScheme.outline.withValues(alpha: 0.3);
}
