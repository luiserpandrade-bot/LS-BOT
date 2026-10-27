import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/fichas_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/cargando_view.dart';
import '../widgets/error_view.dart';
import '../widgets/ficha_card.dart';
import '../widgets/vacio_view.dart';
import 'ficha_detalle_screen.dart';

/// Lista de fichas con filtro por materia, búsqueda y deslizar para recargar.
class FichasScreen extends StatefulWidget {
  const FichasScreen({super.key});

  @override
  State<FichasScreen> createState() => _FichasScreenState();
}

class _FichasScreenState extends State<FichasScreen> {
  final FichasController _fichas = Get.find<FichasController>();
  final _texto = TextEditingController();

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  void _limpiarFiltros() {
    _texto.clear();
    _fichas.limpiarFiltros();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fichas de estudio')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
            child: ValueListenableBuilder(
              valueListenable: _texto,
              builder: (context, valor, _) => TextField(
                controller: _texto,
                onChanged: _fichas.buscar,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Buscar por título o unidad',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: valor.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Borrar búsqueda',
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _texto.clear();
                            _fichas.buscar('');
                          },
                        ),
                ),
              ),
            ),
          ),
          // Pocas materias: una fila desplazable, sin construcción perezosa.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Obx(() {
              final elegida = _fichas.materiaElegida.value;
              return Row(
                children: [
                  _chip('Todas', elegida == null, () => _fichas.elegirMateria(null)),
                  for (final m in _fichas.materias)
                    _chip(m.nombre, elegida == m.codigo, () => _fichas.elegirMateria(m.codigo)),
                ],
              );
            }),
          ),
          const SizedBox(height: AppSpacing.xs),
          Expanded(child: Obx(_contenido)),
        ],
      ),
    );
  }

  Widget _chip(String texto, bool elegido, VoidCallback alElegir) => Padding(
    padding: const EdgeInsets.only(right: AppSpacing.sm),
    child: ChoiceChip(label: Text(texto), selected: elegido, onSelected: (_) => alElegir()),
  );

  Widget _contenido() {
    switch (_fichas.estado.value) {
      case EstadoCarga.cargando:
        return const CargandoView(mensaje: 'Cargando fichas...');
      case EstadoCarga.error:
        return ErrorView(mensaje: _fichas.mensajeError.value, onReintentar: _fichas.recargar);
      case EstadoCarga.vacio:
        final conFiltros = _fichas.hayFiltros;
        return RefreshIndicator(
          onRefresh: _fichas.recargar,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: VacioView(
                  icono: Icons.search_off,
                  titulo: 'No hay fichas',
                  mensaje: conFiltros
                      ? 'Ninguna ficha coincide con la materia o la búsqueda elegidas.'
                      : 'Todavía no hay fichas publicadas.',
                  textoAccion: conFiltros ? 'Ver todas las fichas' : null,
                  onAccion: conFiltros ? _limpiarFiltros : null,
                ),
              ),
            ],
          ),
        );
      case EstadoCarga.exito:
        final lista = _fichas.fichas;
        return RefreshIndicator(
          onRefresh: _fichas.recargar,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
            itemCount: lista.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, i) {
              final ficha = lista[i];
              return FichaCard(
                ficha: ficha,
                onTap: () => Get.to(() => FichaDetalleScreen(id: ficha.id, codigo: ficha.codigo)),
              );
            },
          ),
        );
    }
  }
}
