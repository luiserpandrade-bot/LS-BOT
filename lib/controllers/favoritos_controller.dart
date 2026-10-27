import 'package:get/get.dart';

import '../models/ficha_resumen.dart';
import '../repositories/favoritos_repository.dart';

/// Fichas favoritas de la persona con sesión: Hive guarda y `favoritos`
/// (el espejo reactivo) avisa a las pantallas.
class FavoritosController extends GetxController {
  FavoritosController({FavoritosRepository? repositorio})
    : _repositorio = repositorio ?? Get.find<FavoritosRepository>();

  final FavoritosRepository _repositorio;

  final RxList<FichaResumen> favoritos = <FichaResumen>[].obs;

  /// Lo llama `AuthController` al iniciar o restaurar la sesión.
  Future<void> abrirParaUsuario(int idUsuario) async {
    await _repositorio.abrirParaUsuario(idUsuario);
    favoritos.assignAll(_repositorio.listar());
  }

  bool esFavorito(int id) => favoritos.any((f) => f.id == id);

  /// Agrega la ficha o, si ya estaba, la quita.
  void alternar(FichaResumen ficha) {
    if (esFavorito(ficha.id)) {
      _repositorio.quitar(ficha.id);
      favoritos.removeWhere((f) => f.id == ficha.id);
    } else {
      _repositorio.guardar(ficha);
      favoritos.add(ficha);
    }
  }

  /// Al cerrar sesión: la lista en pantalla se vacía; la caja queda en disco.
  void cerrar() {
    _repositorio.soltar();
    favoritos.clear();
  }
}
