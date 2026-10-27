import 'package:flutter/material.dart';

/// Tema visual de LS-bot: Material 3 con azul oscuro institucional como color
/// principal. Un solo lugar define colores y tipografía de toda la app.
class AppTheme {
  AppTheme._();

  static const Color azulOscuro = Color(0xFF0B3D6E);

  static ThemeData get tema {
    final colores = ColorScheme.fromSeed(seedColor: azulOscuro, primary: azulOscuro);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colores,
      // Una sola familia (Roboto, la de Android) con la escala de Material 3:
      // las pantallas usan `Theme.of(context).textTheme`, nunca tamaños sueltos.
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: colores.surface,
      appBarTheme: AppBarTheme(backgroundColor: azulOscuro, foregroundColor: colores.onPrimary, centerTitle: false),
      navigationBarTheme: NavigationBarThemeData(indicatorColor: colores.primaryContainer),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colores.surfaceContainerLow,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radio)),
      ),
      chipTheme: ChipThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.sm))),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radio)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(48, 48)), // toque accesible
      ),
    );
  }
}

/// Espaciados de toda la app, en vez de números sueltos en cada widget.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  static const double radio = 12;
}
