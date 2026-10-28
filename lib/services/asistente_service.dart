import '../models/respuesta_asistente.dart';
import 'api_client.dart';

/// Asistente LS-bot contra `/asistente`.
class AsistenteService {
  AsistenteService(this._api);

  final ApiClient _api;

  /// La IA puede tardar más que el resto de la API: esta llamada espera
  /// hasta 30 s la respuesta.
  static const tiempoRecepcion = Duration(seconds: 30);

  /// POST /asistente/ — solo envía `materia` y `ficha_id` cuando tienen valor.
  Future<RespuestaAsistente> preguntar(String pregunta, {String? materia, int? fichaId}) async {
    final r = await _api.post(
      ApiException.rutaAsistente,
      data: {'pregunta': pregunta, 'materia': ?materia, 'ficha_id': ?fichaId},
      tiempoRecepcion: tiempoRecepcion,
    );
    return RespuestaAsistente.fromJson(Map<String, dynamic>.from(r.data as Map));
  }
}
