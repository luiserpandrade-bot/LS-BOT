import 'package:flutter/material.dart';

import '../models/mensaje_chat.dart';
import '../models/respuesta_asistente.dart';
import '../theme/app_theme.dart';

/// Burbuja del chat: la persona a la derecha y LS-bot a la izquierda. Bajo
/// cada respuesta van el aviso de IA, la marca de modo reglas y las fuentes.
class BurbujaMensaje extends StatelessWidget {
  const BurbujaMensaje({super.key, required this.mensaje, required this.onAbrirFuente});

  final MensajeChat mensaje;
  final void Function(FuenteAsistente fuente) onAbrirFuente;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final bot = mensaje.esDelBot;
    final secundario = tema.textTheme.bodySmall?.copyWith(color: tema.colorScheme.onSurfaceVariant);
    return Column(
      crossAxisAlignment: bot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        BurbujaBase(
          alDerecha: !bot,
          color: bot ? tema.colorScheme.surfaceContainerHighest : tema.colorScheme.primaryContainer,
          child: SelectableText(
            mensaje.texto,
            style: tema.textTheme.bodyMedium?.copyWith(
              color: bot ? tema.colorScheme.onSurface : tema.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        if (bot) ...[
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Sugerencia de IA: verifica con tu docente', style: secundario),
              if (mensaje.esModoReglas) Text('· modo reglas', style: secundario?.copyWith(fontStyle: FontStyle.italic)),
            ],
          ),
          if (mensaje.fuentes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final f in mensaje.fuentes)
                  ActionChip(
                    avatar: const Icon(Icons.description_outlined, size: 18),
                    label: Text('${f.codigo} · ${f.titulo}'),
                    onPressed: () => onAbrirFuente(f),
                  ),
              ],
            ),
          ],
        ],
      ],
    );
  }
}

/// Forma común de las burbujas (mensajes, «escribiendo…» y errores).
class BurbujaBase extends StatelessWidget {
  const BurbujaBase({super.key, required this.child, required this.color, this.alDerecha = false});

  final Widget child;
  final Color color;
  final bool alDerecha;

  @override
  Widget build(BuildContext context) {
    const radio = Radius.circular(AppSpacing.radio);
    return Align(
      alignment: alDerecha ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              topLeft: radio,
              topRight: radio,
              bottomLeft: alDerecha ? radio : Radius.zero,
              bottomRight: alDerecha ? Radius.zero : radio,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
