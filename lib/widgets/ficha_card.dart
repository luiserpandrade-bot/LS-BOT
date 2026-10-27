import 'package:flutter/material.dart';

import '../models/ficha_resumen.dart';
import '../theme/app_theme.dart';

/// Tarjeta de una ficha en la lista: código, título, unidad, normas y el
/// marcador de favorito.
class FichaCard extends StatelessWidget {
  const FichaCard({
    super.key,
    required this.ficha,
    required this.onTap,
    required this.favorito,
    required this.onFavorito,
  });

  final FichaResumen ficha;
  final VoidCallback onTap;
  final bool favorito;
  final VoidCallback onFavorito;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.xs, AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _datos(tema)),
              BotonFavorito(favorito: favorito, onPressed: onFavorito),
            ],
          ),
        ),
      ),
    );
  }

  Widget _datos(ThemeData tema) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(ficha.codigo, style: tema.textTheme.labelMedium?.copyWith(color: tema.colorScheme.primary)),
      const SizedBox(height: AppSpacing.xs),
      Text(ficha.titulo, style: tema.textTheme.titleMedium),
      const SizedBox(height: AppSpacing.xs),
      Text(
        'Unidad ${ficha.unidad} · ${ficha.unidadNombre}',
        style: tema.textTheme.bodySmall?.copyWith(color: tema.colorScheme.onSurfaceVariant),
      ),
      if (ficha.normas.isNotEmpty) ...[const SizedBox(height: AppSpacing.sm), NormasChips(normas: ficha.normas)],
    ],
  );
}

/// Marcador para agregar o quitar una ficha de Favoritos.
class BotonFavorito extends StatelessWidget {
  const BotonFavorito({super.key, required this.favorito, required this.onPressed});

  final bool favorito;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: favorito ? 'Quitar de favoritos' : 'Agregar a favoritos',
    icon: Icon(favorito ? Icons.bookmark : Icons.bookmark_border),
    onPressed: onPressed,
  );
}

/// Normas citadas por una ficha, como chips.
class NormasChips extends StatelessWidget {
  const NormasChips({super.key, required this.normas});

  final List<String> normas;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final norma in normas)
          Chip(
            label: Text(norma),
            avatar: const Icon(Icons.rule, size: 16),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
      ],
    );
  }
}
