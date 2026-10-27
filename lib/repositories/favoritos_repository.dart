import 'package:hive/hive.dart';

import '../models/ficha_resumen.dart';

/// Fichas favoritas guardadas en Hive, una caja por usuario
/// (`favoritos_<idUsuario>`). No son datos sensibles: la caja sobrevive al
/// cierre de la app y al cierre de sesión.
class FavoritosRepository {
  Box<Map>? _caja;

  /// Abre (o crea) la caja de la persona que acaba de entrar.
  Future<void> abrirParaUsuario(int idUsuario) async {
    _caja = await Hive.openBox<Map>('favoritos_$idUsuario');
  }

  List<FichaResumen> listar() {
    final caja = _caja;
    if (caja == null || !caja.isOpen) return const [];
    return caja.values.map((m) => FichaResumen.fromJson(Map<String, dynamic>.from(m))).toList();
  }

  // Hive cambia la memoria al instante y escribe a disco detrás: la interfaz
  // no espera al disco.
  void guardar(FichaResumen ficha) => _caja?.put(ficha.id, ficha.toJson());

  void quitar(int id) => _caja?.delete(id);

  /// Al cerrar sesión se deja de usar la caja, sin borrarla.
  void soltar() => _caja = null;
}
