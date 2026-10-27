import '../models/ficha_detalle.dart';
import '../models/ficha_resumen.dart';
import '../models/materia.dart';
import 'api_client.dart';

/// Fichas de estudio (solo lectura) contra `/fichas`.
class FichasService {
  FichasService(this._api);

  final ApiClient _api;

  /// GET /fichas/materias.
  Future<List<Materia>> materias() async {
    final r = await _api.get('/fichas/materias');
    return (r.data as List).map((e) => Materia.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// GET /fichas/ — solo envía `materia` y `q` cuando tienen valor.
  Future<List<FichaResumen>> listar({String? materia, String? q}) async {
    final texto = q?.trim() ?? '';
    final r = await _api.get(
      '/fichas/',
      query: {if (materia != null && materia.isNotEmpty) 'materia': materia, if (texto.isNotEmpty) 'q': texto},
    );
    return (r.data as List).map((e) => FichaResumen.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// GET /fichas/{id}.
  Future<FichaDetalle> detalle(int id) async {
    final r = await _api.get('/fichas/$id');
    return FichaDetalle.fromJson(Map<String, dynamic>.from(r.data as Map));
  }
}
