import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Estado vacío reutilizable: la carga terminó sin error pero no hay datos.
/// Con `textoAccion` y `onAccion` muestra un botón para no dejar un callejón
/// sin salida.
class VacioView extends StatelessWidget {
  const VacioView({
    super.key,
    required this.mensaje,
    this.titulo,
    this.icono = Icons.inbox_outlined,
    this.textoAccion,
    this.onAccion,
  });

  final String mensaje;
  final String? titulo;
  final IconData icono;
  final String? textoAccion;
  final VoidCallback? onAccion;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 56, color: tema.colorScheme.outline),
            const SizedBox(height: AppSpacing.md),
            if (titulo != null) ...[
              Text(titulo!, textAlign: TextAlign.center, style: tema.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
            ],
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: tema.textTheme.bodyMedium?.copyWith(color: tema.colorScheme.onSurfaceVariant),
            ),
            if (textoAccion != null && onAccion != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.tonal(onPressed: onAccion, child: Text(textoAccion!)),
            ],
          ],
        ),
      ),
    );
  }
}
