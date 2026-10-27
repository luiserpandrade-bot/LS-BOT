import 'package:get/get.dart';

import '../models/ficha_detalle.dart';
import '../models/ficha_resumen.dart';
import '../models/materia.dart';
import '../services/api_client.dart';
import '../services/fichas_service.dart';

/// Estados de una pantalla con datos.
enum EstadoCarga { cargando, vacio, error, exito }

/// Lista de fichas (filtros, búsqueda y estado) y detalle de la ficha abierta.
class FichasController extends GetxController {
  FichasController({FichasService? servicio}) : _servicio = servicio ?? Get.find<FichasService>();

  final FichasService _servicio;

  final RxList<Materia> materias = Materia.conocidas.toList().obs;

  /// Código de la materia elegida; null = «Todas».
  final RxnString materiaElegida = RxnString();
  final RxString busqueda = ''.obs;

  final RxList<FichaResumen> fichas = <FichaResumen>[].obs;
  final Rx<EstadoCarga> estado = EstadoCarga.cargando.obs;
  final RxString mensajeError = ''.obs;

  final Rxn<FichaDetalle> detalle = Rxn<FichaDetalle>();
  final Rx<EstadoCarga> estadoDetalle = EstadoCarga.cargando.obs;
  final RxString errorDetalle = ''.obs;

  // Cada carga lleva un número; una respuesta vieja (de un filtro anterior)
  // se descarta para no pisar la lista actual.
  int _cargaActual = 0;
  int? _detalleActual;
  late final Worker _esperaBusqueda;

  @override
  void onInit() {
    super.onInit();
    // Espera a que la persona deje de escribir antes de consultar.
    _esperaBusqueda = debounce(busqueda, (_) => cargar(), time: const Duration(milliseconds: 400));
    cargarMaterias();
    cargar();
  }

  @override
  void onClose() {
    _esperaBusqueda.dispose();
    super.onClose();
  }

  /// GET /fichas/materias. Si falla, se quedan las tres materias conocidas:
  /// la lista principal ya muestra su propio error.
  Future<void> cargarMaterias() async {
    try {
      final lista = await _servicio.materias();
      if (lista.isNotEmpty) materias.assignAll(lista);
    } on ApiException {
      // Sin cambios: los filtros siguen disponibles.
    }
  }

  /// GET /fichas/ con la materia elegida y el texto de búsqueda.
  Future<void> cargar() async {
    final numero = ++_cargaActual;
    estado.value = EstadoCarga.cargando;
    mensajeError.value = '';
    try {
      final lista = await _servicio.listar(materia: materiaElegida.value, q: busqueda.value);
      if (numero != _cargaActual) return;
      fichas.assignAll(lista);
      estado.value = lista.isEmpty ? EstadoCarga.vacio : EstadoCarga.exito;
    } on ApiException catch (e) {
      if (numero != _cargaActual) return;
      fichas.clear();
      mensajeError.value = e.mensaje;
      estado.value = EstadoCarga.error;
    }
  }

  /// Para el «deslizar para recargar» y el botón Reintentar.
  Future<void> recargar() => cargar();

  void elegirMateria(String? codigo) {
    if (materiaElegida.value == codigo) return;
    materiaElegida.value = codigo;
    cargar();
  }

  void buscar(String texto) => busqueda.value = texto;

  bool get hayFiltros => materiaElegida.value != null || busqueda.value.trim().isNotEmpty;

  /// Vuelve a «Todas» sin texto de búsqueda.
  void limpiarFiltros() {
    materiaElegida.value = null;
    busqueda.value = '';
    cargar();
  }

  /// GET /fichas/{id} para la pantalla de detalle.
  Future<void> cargarDetalle(int id) async {
    _detalleActual = id;
    detalle.value = null;
    estadoDetalle.value = EstadoCarga.cargando;
    errorDetalle.value = '';
    try {
      final ficha = await _servicio.detalle(id);
      if (_detalleActual != id) return;
      detalle.value = ficha;
      estadoDetalle.value = EstadoCarga.exito;
    } on ApiException catch (e) {
      if (_detalleActual != id) return;
      errorDetalle.value = e.mensaje;
      estadoDetalle.value = EstadoCarga.error;
    }
  }
}
