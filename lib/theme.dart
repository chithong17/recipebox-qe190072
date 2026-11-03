import 'package:flutter/material.dart';

abstract final class Tokens {
  static const background = Color(0xFFF7F8F3),
      primary = Color(0xFF2F8F62),
      primaryDark = Color(0xFF236F4B),
      soft = Color(0xFFE7F3EB),
      ink = Color(0xFF202923),
      gold = Color(0xFFE5A92E),
      error = Color(0xFFC74747);
  static const gap = 16.0,
      small = 8.0,
      padding = 20.0,
      radius = 20.0,
      inputRadius = 14.0,
      touch = 52.0;
}

ThemeData appTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final scheme = ColorScheme.fromSeed(seedColor: Tokens.primary, brightness: b)
      .copyWith(
        primary: dark ? const Color(0xFF8BD7AE) : Tokens.primaryDark,
        surface: dark ? const Color(0xFF17211B) : Colors.white,
        error: dark ? const Color(0xFFFFB4AB) : Tokens.error,
      );
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(Tokens.inputRadius),
    borderSide: BorderSide(color: scheme.outlineVariant),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark ? const Color(0xFF101813) : Tokens.background,
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? const Color(0xFF101813) : Tokens.background,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
    ),
    textTheme: ThemeData(brightness: b).textTheme.apply(
      bodyColor: dark ? Colors.white : Tokens.ink,
      displayColor: dark ? Colors.white : Tokens.ink,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Tokens.radius),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .4)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      border: border,
      enabledBorder: border,
      contentPadding: const EdgeInsets.all(Tokens.gap),
      errorMaxLines: 3,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, Tokens.touch),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.inputRadius),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, Tokens.touch),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.inputRadius),
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
  );
}
