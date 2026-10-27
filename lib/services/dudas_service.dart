import '../models/duda.dart';
import 'api_client.dart';

/// Dudas de cada ficha. El servidor decide quién puede editar o borrar
/// (403 si la duda no es tuya, 404 si ya no existe).
class DudasService {
  DudasService(this._api);

  final ApiClient _api;

  /// GET /fichas/{id}/dudas — de la más nueva a la más antigua.
  Future<List<Duda>> listar(int fichaId) async {
    final r = await _api.get('/fichas/$fichaId/dudas');
    return (r.data as List).map((e) => Duda.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// POST /fichas/{id}/dudas → 201.
  Future<Duda> crear(int fichaId, String texto) async {
    final r = await _api.post('/fichas/$fichaId/dudas', data: {'texto': texto});
    return Duda.fromJson(Map<String, dynamic>.from(r.data as Map));
  }

  /// PATCH /dudas/{id}.
  Future<Duda> editar(int id, String texto) async {
    final r = await _api.patch('/dudas/$id', data: {'texto': texto});
    return Duda.fromJson(Map<String, dynamic>.from(r.data as Map));
  }

  /// DELETE /dudas/{id} → 204 sin cuerpo.
  Future<void> borrar(int id) async {
    await _api.delete('/dudas/$id');
  }
}
