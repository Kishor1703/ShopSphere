import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const marine = Color(0xFF0B3C5D);
  static const amber = Color(0xFFF2A900);
  static const onAmber = Color(0xFF2B1D00);
  static const surface = Color(0xFFF4F6F9);
  static const success = Color(0xFF1E7A4C);
}

class AppSpacing {
  const AppSpacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

class AppRadius {
  const AppRadius._();

  static const card = 16.0;
  static const control = 12.0;
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.marine,
    brightness: Brightness.light,
  ).copyWith(secondary: AppColors.amber, onSecondary: AppColors.onAmber);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.surface,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

/// Shared text-field decoration so every input looks the same.
InputDecoration appInputDecoration(
  BuildContext context, {
  required String label,
  IconData? icon,
  Widget? suffix,
  String? hint,
}) {
  final scheme = Theme.of(context).colorScheme;
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: icon == null ? null : Icon(icon),
    suffixIcon: suffix,
    filled: true,
    fillColor: Colors.white,
    border: border(scheme.outlineVariant),
    enabledBorder: border(scheme.outlineVariant),
    focusedBorder: border(scheme.primary, 2),
    errorBorder: border(scheme.error),
    focusedErrorBorder: border(scheme.error, 2),
  );
}
