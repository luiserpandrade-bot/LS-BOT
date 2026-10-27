import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/dudas_controller.dart';
import '../controllers/fichas_controller.dart';
import '../models/duda.dart';
import '../theme/app_theme.dart';
import 'cargando_view.dart';
import 'duda_formulario.dart';
import 'duda_tile.dart';
import 'error_view.dart';
import 'vacio_view.dart';

/// Sección «Dudas de la comunidad» al final del detalle de una ficha, con
/// sus estados de carga, vacío y error.
class DudasSeccion extends StatelessWidget {
  const DudasSeccion({super.key, required this.dudas, required this.totalInicial});

  final DudasController dudas;

  /// `total_dudas` del detalle: se muestra mientras la lista carga.
  final int totalInicial;

  Future<void> _abrirFormulario(BuildContext context, {Duda? duda}) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => DudaFormulario(
      titulo: duda == null ? 'Publicar duda' : 'Editar duda',
      textoBoton: duda == null ? 'Publicar' : 'Guardar',
      textoInicial: duda?.texto,
      alEnviar: (texto) => duda == null ? dudas.publicar(texto) : dudas.editar(duda, texto),
    ),
  );

  Future<void> _borrar(BuildContext context, Duda duda) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('¿Borrar esta duda?'),
        content: const Text('Se borrará para todos los usuarios. Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(contexto).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(contexto).pop(true), child: const Text('Borrar')),
        ],
      ),
    );
    if (confirmado != true || !context.mounted) return;
    final mensajes = ScaffoldMessenger.of(context);
    final error = await dudas.borrar(duda);
    mensajes.showSnackBar(SnackBar(content: Text(error ?? 'Duda borrada.')));
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Obx(() {
      final estado = dudas.estado.value;
      final total = estado == EstadoCarga.cargando || estado == EstadoCarga.error ? totalInicial : dudas.dudas.length;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(child: Text('Dudas de la comunidad ($total)', style: tema.textTheme.titleMedium)),
                FilledButton.tonalIcon(
                  onPressed: dudas.enviando.value ? null : () => _abrirFormulario(context),
                  icon: const Icon(Icons.add_comment_outlined),
                  label: const Text('Publicar duda'),
                ),
              ],
            ),
          ),
          ..._contenido(context, estado),
        ],
      );
    });
  }

  List<Widget> _contenido(BuildContext context, EstadoCarga estado) {
    switch (estado) {
      case EstadoCarga.cargando:
        return const [
          Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: CargandoView(mensaje: 'Cargando dudas...'),
          ),
        ];
      case EstadoCarga.error:
        return [ErrorView(mensaje: dudas.mensajeError.value, onReintentar: dudas.recargar)];
      case EstadoCarga.vacio:
        return const [
          VacioView(
            icono: Icons.forum_outlined,
            mensaje: 'Aún no hay dudas en esta ficha. ¡Sé el primero en preguntar!',
          ),
        ];
      case EstadoCarga.exito:
        return [
          for (final duda in dudas.dudas)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: DudaTile(
                duda: duda,
                onEditar: () => _abrirFormulario(context, duda: duda),
                onBorrar: () => _borrar(context, duda),
              ),
            ),
        ];
    }
  }
}
