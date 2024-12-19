// lib/core/app/app_theme.dart
import 'package:flutter/material.dart';

final theme = _getTheme(
  ColorScheme.fromSeed(
    seedColor: Colors.blue, // You can change this to your app's primary color
    brightness: Brightness.light,
  ),
);

final darkTheme = _getTheme(
  ColorScheme.fromSeed(
    seedColor: Colors.blue, // You can change this to your app's primary color
    brightness: Brightness.dark,
  ),
);

ThemeData _getTheme(ColorScheme colorScheme) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    textTheme: _getTextTheme(colorScheme),
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    ),
  );
}

TextTheme _getTextTheme(ColorScheme colorScheme) {
  return TextTheme(
    displayLarge: TextStyle(color: colorScheme.onSurface),
    displayMedium: TextStyle(color: colorScheme.onSurface),
    displaySmall: TextStyle(color: colorScheme.onSurface),
    headlineLarge: TextStyle(color: colorScheme.onSurface),
    headlineMedium: TextStyle(color: colorScheme.onSurface),
    headlineSmall: TextStyle(color: colorScheme.onSurface),
    titleLarge: TextStyle(color: colorScheme.onSurface),
    titleMedium: TextStyle(color: colorScheme.onSurface),
    titleSmall: TextStyle(color: colorScheme.onSurface),
    bodyLarge: TextStyle(color: colorScheme.onSurface),
    bodyMedium: TextStyle(color: colorScheme.onSurface),
    bodySmall: TextStyle(color: colorScheme.onSurface),
    labelLarge: TextStyle(color: colorScheme.onSurface),
    labelMedium: TextStyle(color: colorScheme.onSurface),
    labelSmall: TextStyle(color: colorScheme.onSurface),
  );
}
