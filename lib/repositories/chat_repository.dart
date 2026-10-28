import 'package:hive/hive.dart';

import '../models/mensaje_chat.dart';

/// Historial del chat con LS-bot en Hive, una caja por usuario
/// (`chat_<idUsuario>`) con los últimos [maximo] mensajes. Sobrevive al
/// cierre de la app, pero las preguntas son datos de la persona: al cerrar
/// sesión la caja se borra del disco.
class ChatRepository {
  static const maximo = 50;

  Box<Map>? _caja;

  /// Abre (o crea) la caja de la persona que acaba de entrar.
  Future<void> abrirParaUsuario(int idUsuario) async {
    _caja = await Hive.openBox<Map>('chat_$idUsuario');
  }

  /// Del más antiguo al más reciente (las claves de `add` son crecientes).
  List<MensajeChat> listar() {
    final caja = _caja;
    if (caja == null || !caja.isOpen) return const [];
    return caja.values.map((m) => MensajeChat.fromJson(Map<String, dynamic>.from(m))).toList();
  }

  /// Guarda el mensaje y descarta los más antiguos por encima de [maximo].
  Future<void> agregar(MensajeChat mensaje) async {
    final caja = _caja;
    if (caja == null || !caja.isOpen) return;
    await caja.add(mensaje.toJson());
    while (caja.length > maximo) {
      await caja.deleteAt(0);
    }
  }

  Future<void> vaciar() async => _caja?.clear();

  /// Al cerrar sesión: borra la caja del disco y deja de usarla.
  Future<void> borrarDelDisco() async {
    final caja = _caja;
    _caja = null;
    if (caja == null || !caja.isOpen) return;
    try {
      await caja.deleteFromDisk();
    } on UnsupportedError {
      // Las cajas en memoria (pruebas) no tienen archivo: Hive ya la cerró y
      // descartó su contenido antes de lanzar este error.
    }
  }
}
