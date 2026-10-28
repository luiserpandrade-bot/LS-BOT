import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/asistente_controller.dart';
import '../controllers/dudas_controller.dart';
import '../controllers/favoritos_controller.dart';
import '../controllers/fichas_controller.dart';
import '../controllers/navegacion_controller.dart';
import '../models/ficha_detalle.dart';
import '../theme/app_theme.dart';
import '../widgets/cargando_view.dart';
import '../widgets/dudas_seccion.dart';
import '../widgets/error_view.dart';
import '../widgets/ficha_card.dart';

/// Contenido completo de una ficha, con su propio estado de carga y error, y
/// al final las dudas de la comunidad.
class FichaDetalleScreen extends StatefulWidget {
  const FichaDetalleScreen({super.key, required this.id, required this.codigo});

  final int id;
  final String codigo;

  @override
  State<FichaDetalleScreen> createState() => _FichaDetalleScreenState();
}

class _FichaDetalleScreenState extends State<FichaDetalleScreen> {
  final FichasController _fichas = Get.find<FichasController>();
  final DudasController _dudas = Get.find<DudasController>();
  final FavoritosController _favoritos = Get.find<FavoritosController>();

  @override
  void initState() {
    super.initState();
    _fichas.cargarDetalle(widget.id);
    _dudas.cargar(widget.id);
  }

  /// Fija la ficha como contexto del chat y vuelve a Home en la pestaña LS-bot.
  void _preguntarALsBot(FichaDetalle ficha) {
    Get.find<AsistenteController>().fijarFicha(ficha);
    Get.find<NavegacionController>().irA(NavegacionController.lsBot);
    Get.until((ruta) => ruta.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Siempre a mano mientras se lee la ficha, sin mover su contenido.
      floatingActionButton: Obx(() {
        final ficha = _fichas.detalle.value;
        if (_fichas.estadoDetalle.value != EstadoCarga.exito || ficha == null || ficha.id != widget.id) {
          return const SizedBox.shrink();
        }
        return FloatingActionButton.extended(
          onPressed: () => _preguntarALsBot(ficha),
          icon: const Icon(Icons.smart_toy_outlined),
          label: const Text('Preguntar a LS-bot sobre esta ficha'),
        );
      }),
      appBar: AppBar(
        title: Text(widget.codigo),
        actions: [
          Obx(() {
            final ficha = _fichas.detalle.value;
            if (ficha == null || ficha.id != widget.id) return const SizedBox.shrink();
            return BotonFavorito(
              favorito: _favoritos.esFavorito(ficha.id),
              onPressed: () => _favoritos.alternar(ficha),
            );
          }),
        ],
      ),
      body: Obx(() {
        switch (_fichas.estadoDetalle.value) {
          case EstadoCarga.cargando:
          case EstadoCarga.vacio:
            return const CargandoView(mensaje: 'Cargando ficha...');
          case EstadoCarga.error:
            return ErrorView(mensaje: _fichas.errorDetalle.value, onReintentar: () => _fichas.cargarDetalle(widget.id));
          case EstadoCarga.exito:
            final ficha = _fichas.detalle.value;
            if (ficha == null) return const CargandoView(mensaje: 'Cargando ficha...');
            return _Contenido(ficha: ficha, dudas: _dudas);
        }
      }),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.ficha, required this.dudas});

  final FichaDetalle ficha;
  final DudasController dudas;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final secundario = tema.textTheme.bodyMedium?.copyWith(color: tema.colorScheme.onSurfaceVariant);
    // Deslizar para recargar actualiza las dudas; la ficha no cambia.
    return RefreshIndicator(
      onRefresh: dudas.recargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        // Abajo queda espacio (alto del botón flotante, 56, más margen) para
        // que no tape la última duda.
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 56 + AppSpacing.xxl),
        children: [
          Text(ficha.titulo, style: tema.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(ficha.materiaNombre, style: tema.textTheme.titleSmall?.copyWith(color: tema.colorScheme.primary)),
          const SizedBox(height: AppSpacing.xs),
          Text('Unidad ${ficha.unidad} · ${ficha.unidadNombre}', style: secundario),
          if (ficha.silabo.isNotEmpty) ...[
            const _Titulo('Sílabo'),
            Text(ficha.silabo, style: tema.textTheme.bodyMedium),
          ],
          if (ficha.ideasClave.isNotEmpty) ...[
            const _Titulo('Ideas clave'),
            _Lista(elementos: ficha.ideasClave, icono: Icons.lightbulb_outline),
          ],
          if (ficha.formulas.isNotEmpty) ...[
            const _Titulo('Fórmulas'),
            for (final formula in ficha.formulas)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: tema.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: SelectableText(formula, style: tema.textTheme.bodyMedium),
              ),
          ],
          if (ficha.preguntas.isNotEmpty) ...[
            const _Titulo('Preguntas de refuerzo'),
            _Lista(elementos: ficha.preguntas, icono: Icons.help_outline),
          ],
          if (ficha.normas.isNotEmpty) ...[const _Titulo('Normas'), NormasChips(normas: ficha.normas)],
          if (ficha.fuente.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Text('Fuente: ${ficha.fuente}', style: tema.textTheme.bodySmall),
          ],
          DudasSeccion(dudas: dudas, totalInicial: ficha.totalDudas),
        ],
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.sm),
    child: Text(texto, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _Lista extends StatelessWidget {
  const _Lista({required this.elementos, required this.icono});

  final List<String> elementos;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      children: [
        for (final e in elementos)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icono, size: 18, color: tema.colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(e, style: tema.textTheme.bodyMedium)),
              ],
            ),
          ),
      ],
    );
  }
}
