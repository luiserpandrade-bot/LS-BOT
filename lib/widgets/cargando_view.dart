import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Estado de carga reutilizable.
class CargandoView extends StatelessWidget {
  const CargandoView({super.key, this.mensaje = 'Cargando...'});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.md),
          Text(mensaje, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
