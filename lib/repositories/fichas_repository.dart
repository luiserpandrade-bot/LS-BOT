import 'package:hive/hive.dart';

import '../models/ficha_resumen.dart';
import '../services/api_client.dart';
import '../services/fichas_service.dart';

/// Lista de fichas con respaldo sin conexión: primero el servidor y, solo si
/// falla la red o el servidor (5xx), la última copia guardada en Hive para
/// ese mismo filtro. Un 401 o un 4xx no usan la caché: no son fallas de
/// infraestructura. Las fichas no son datos personales: una sola caja.
class FichasRepository {
  FichasRepository(this._servicio);

  final FichasService _servicio;

  static const nombreCaja = 'fichas_cache';
  static const _claveFichas = 'fichas';
  static const _claveSincronizado = 'sincronizado';

  /// Se llama en `main()`, después de `Hive.initFlutter()`.
  static Future<void> abrirCaja() => Hive.openBox<Map>(nombreCaja);

  Box<Map>? get _caja => Hive.isBoxOpen(nombreCaja) ? Hive.box<Map>(nombreCaja) : null;

  /// Devuelve la lista y, si vino de la caché, la hora de su última
  /// sincronización (null = respuesta fresca del servidor).
  Future<(List<FichaResumen>, DateTime?)> listar({String? materia, String? q}) async {
    final clave = _clave(materia, q);
    try {
      final lista = await _servicio.listar(materia: materia, q: q);
      // Cada carga exitosa reemplaza la copia anterior de ese filtro.
      _caja?.put(clave, {
        _claveFichas: lista.map((f) => f.toJson()).toList(),
        _claveSincronizado: DateTime.now().toIso8601String(),
      });
      return (lista, null);
    } on ApiException catch (e) {
      final codigo = e.statusCode;
      final fallaDeInfraestructura = codigo == null || codigo >= 500;
      if (!fallaDeInfraestructura) rethrow;
      final guardado = _caja?.get(clave);
      final fichas = guardado?[_claveFichas];
      final fecha = DateTime.tryParse('${guardado?[_claveSincronizado]}');
      if (fichas is! List || fecha == null) rethrow;
      return (fichas.map((m) => FichaResumen.fromJson(Map<String, dynamic>.from(m as Map))).toList(), fecha);
    }
  }

  String _clave(String? materia, String? q) => '${materia ?? 'todas'}|${q?.trim().toLowerCase() ?? ''}';
}
