import 'package:flutter/material.dart';

import '../models/duda.dart';
import '../theme/app_theme.dart';
import '../utils/fechas.dart';

enum _AccionDuda { editar, borrar }

/// Una duda de la comunidad: autor, fecha, marca «editada» y texto. Solo las
/// propias (`esMia`) muestran el menú con Editar y Borrar.
class DudaTile extends StatelessWidget {
  const DudaTile({super.key, required this.duda, required this.onEditar, required this.onBorrar});

  final Duda duda;
  final VoidCallback onEditar;
  final VoidCallback onBorrar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final secundario = tema.textTheme.bodySmall?.copyWith(color: tema.colorScheme.onSurfaceVariant);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.xs, AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(duda.autor, style: tema.textTheme.titleSmall),
                      Text(
                        duda.fueEditada ? '${fechaLegible(duda.creado)} · editada' : fechaLegible(duda.creado),
                        style: secundario,
                      ),
                    ],
                  ),
                ),
                if (duda.esMia)
                  PopupMenuButton<_AccionDuda>(
                    tooltip: 'Opciones de la duda',
                    onSelected: (accion) => accion == _AccionDuda.editar ? onEditar() : onBorrar(),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: _AccionDuda.editar, child: Text('Editar')),
                      PopupMenuItem(value: _AccionDuda.borrar, child: Text('Borrar')),
                    ],
                  )
                else
                  // Misma altura con o sin menú.
                  const SizedBox(height: 48),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Text(duda.texto, style: tema.textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}
