import 'package:get/get.dart';

import '../models/duda.dart';
import '../services/api_client.dart';
import '../services/dudas_service.dart';
import 'fichas_controller.dart';

/// Dudas de la ficha abierta: lista con su estado y las acciones de publicar,
/// editar y borrar. Las acciones devuelven null si salieron bien o el mensaje
/// de `ApiException` para mostrarlo sin cerrar la pantalla.
class DudasController extends GetxController {
  DudasController({DudasService? servicio}) : _servicio = servicio ?? Get.find<DudasService>();

  final DudasService _servicio;

  final RxList<Duda> dudas = <Duda>[].obs;
  final Rx<EstadoCarga> estado = EstadoCarga.cargando.obs;
  final RxString mensajeError = ''.obs;

  /// `true` mientras se publica, edita o borra una duda.
  final RxBool enviando = false.obs;

  int? _fichaId;
  int? get fichaId => _fichaId;

  // Igual que en `FichasController`: una respuesta vieja (de otra ficha o de
  // una carga anterior) se descarta.
  int _cargaActual = 0;

  /// GET /fichas/{id}/dudas mostrando el estado de carga.
  Future<void> cargar(int fichaId) {
    _fichaId = fichaId;
    return _cargar(mostrarCarga: true);
  }

  /// Para el «deslizar para recargar» y el botón Reintentar.
  Future<void> recargar() => _cargar(mostrarCarga: true);

  /// Después de un cambio se recarga sin pasar por «cargando»: la lista
  /// actual sigue a la vista hasta que llega la nueva.
  Future<void> _cargar({required bool mostrarCarga}) async {
    final id = _fichaId;
    if (id == null) return;
    final numero = ++_cargaActual;
    if (mostrarCarga) {
      estado.value = EstadoCarga.cargando;
      mensajeError.value = '';
    }
    try {
      final lista = await _servicio.listar(id);
      if (numero != _cargaActual) return;
      dudas.assignAll(lista);
      mensajeError.value = '';
      estado.value = lista.isEmpty ? EstadoCarga.vacio : EstadoCarga.exito;
    } on ApiException catch (e) {
      if (numero != _cargaActual) return;
      dudas.clear();
      mensajeError.value = e.mensaje;
      estado.value = EstadoCarga.error;
    }
  }

  /// POST /fichas/{id}/dudas.
  Future<String?> publicar(String texto) {
    final id = _fichaId;
    if (id == null) return Future.value(ApiException.mensajeNoEncontrado);
    return _cambiar(() => _servicio.crear(id, texto.trim()));
  }

  /// PATCH /dudas/{id}.
  Future<String?> editar(Duda duda, String texto) => _cambiar(() => _servicio.editar(duda.id, texto.trim()));

  /// DELETE /dudas/{id}.
  Future<String?> borrar(Duda duda) => _cambiar(() => _servicio.borrar(duda.id));

  Future<String?> _cambiar(Future<void> Function() accion) async {
    enviando.value = true;
    try {
      await accion();
      await _cargar(mostrarCarga: false);
      return null;
    } on ApiException catch (e) {
      // 404: otra sesión ya la borró; la lista recargada lo refleja.
      if (e.statusCode == 404) await _cargar(mostrarCarga: false);
      return e.mensaje;
    } finally {
      enviando.value = false;
    }
  }
}
