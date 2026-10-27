import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/fechas.dart';

/// Banda fija sobre una lista que se muestra desde la copia guardada.
class AvisoSinConexion extends StatelessWidget {
  const AvisoSinConexion({super.key, required this.sincronizado, required this.onReintentar});

  final DateTime sincronizado;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final color = tema.colorScheme.onSecondaryContainer;
    return Material(
      color: tema.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.sm, AppSpacing.xs),
        child: Row(
          children: [
            Icon(Icons.cloud_off, size: 20, color: color),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Sin conexión — fichas guardadas (última sincronización: ${fechaCorta(sincronizado)})',
                style: tema.textTheme.bodySmall?.copyWith(color: color),
              ),
            ),
            TextButton(onPressed: onReintentar, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
