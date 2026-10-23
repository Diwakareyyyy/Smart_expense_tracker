import 'package:flutter/material.dart';

/// Theme-aware color helpers used across all screens.
extension ThemeContext on BuildContext {
  bool get isDarkTheme => Theme.of(this).brightness == Brightness.dark;

  Color get appBg =>
      isDarkTheme ? const Color(0xff070B16) : const Color(0xffF5F7FA);

  Color get cardBg =>
      isDarkTheme ? const Color(0xff1B233A) : Colors.white;

  Color get cardBgAlt =>
      isDarkTheme ? const Color(0xff1B1B28) : const Color(0xffEEF0F4);

  Color get textPrimary =>
      isDarkTheme ? Colors.white : const Color(0xff1A1A2E);

  Color get textSecondary =>
      isDarkTheme ? Colors.white70 : Colors.black54;

  Color get textMuted =>
      isDarkTheme ? Colors.white54 : Colors.black45;

  Color get iconBg =>
      isDarkTheme ? const Color(0xff2A2540) : const Color(0xffEDE9FE);

  Color get iconFg =>
      isDarkTheme ? Colors.white : const Color(0xff7B4DFF);

  Color get bottomBarBg =>
      isDarkTheme ? const Color(0xff1B1B28) : Colors.white;

  Color get bottomBarIcon =>
      isDarkTheme ? Colors.white70 : Colors.black54;

  Color get inputFill =>
      isDarkTheme ? const Color(0xff1B233A) : Colors.white;

  Color get divider =>
      isDarkTheme ? Colors.white24 : Colors.grey.shade300;

  Color get progressBg =>
      isDarkTheme ? Colors.white10 : Colors.grey.shade200;

  Color get shadowColor =>
      isDarkTheme ? Colors.transparent : Colors.black.withValues(alpha: 0.06);

  BoxDecoration get cardDecoration => BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        boxShadow: isDarkTheme
            ? null
            : [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      );
}
