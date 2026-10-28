import 'package:get/get.dart';

import '../models/ficha_resumen.dart';
import '../models/mensaje_chat.dart';
import '../repositories/chat_repository.dart';
import '../services/api_client.dart';
import '../services/asistente_service.dart';
import '../utils/validadores.dart';

/// Chat con LS-bot de la persona con sesión: Hive guarda el historial y
/// `mensajes` (el espejo reactivo) avisa a la pantalla. Las preguntas y
/// respuestas nunca se escriben en los registros.
class AsistenteController extends GetxController {
  AsistenteController({AsistenteService? servicio, ChatRepository? repositorio})
    : _servicio = servicio ?? Get.find<AsistenteService>(),
      _repositorio = repositorio ?? Get.find<ChatRepository>();

  final AsistenteService _servicio;
  final ChatRepository _repositorio;

  final RxList<MensajeChat> mensajes = <MensajeChat>[].obs;
  final RxBool enviando = false.obs;

  /// Código de materia que acota la búsqueda (null = todas).
  final Rxn<String> materia = Rxn<String>();

  /// Ficha que la persona estaba viendo; se envía como `ficha_id`.
  final Rxn<FichaResumen> fichaContexto = Rxn<FichaResumen>();

  /// Mensaje de `ApiException` del último envío fallido ('' = sin error).
  final RxString mensajeError = ''.obs;

  // Lo necesario para «Reintentar»: la pregunta ya está en el historial.
  ({String pregunta, String? materia, int? fichaId})? _fallido;

  /// Lo llama `AuthController` al iniciar o restaurar la sesión.
  Future<void> abrirParaUsuario(int idUsuario) async {
    await _repositorio.abrirParaUsuario(idUsuario);
    mensajes.assignAll(_repositorio.listar());
  }

  /// Valida y envía la pregunta. Devuelve el error de validación para
  /// mostrarlo en el campo, o null si se envió.
  Future<String?> enviar(String texto) async {
    final error = Validadores.pregunta(texto);
    if (error != null) return error;
    if (enviando.value) return null;
    final pregunta = texto.trim();
    await _agregar(MensajeChat(rol: RolMensaje.usuario, texto: pregunta, fecha: DateTime.now()));
    await _preguntar((pregunta: pregunta, materia: materia.value, fichaId: fichaContexto.value?.id));
    return null;
  }

  /// Vuelve a enviar la última pregunta que falló, sin repetirla en el chat.
  Future<void> reintentar() async {
    final fallido = _fallido;
    if (fallido == null || enviando.value) return;
    await _preguntar(fallido);
  }

  Future<void> _preguntar(({String pregunta, String? materia, int? fichaId}) peticion) async {
    enviando.value = true;
    mensajeError.value = '';
    _fallido = null;
    try {
      final r = await _servicio.preguntar(peticion.pregunta, materia: peticion.materia, fichaId: peticion.fichaId);
      await _agregar(
        MensajeChat(rol: RolMensaje.bot, texto: r.respuesta, fecha: DateTime.now(), modo: r.modo, fuentes: r.fuentes),
      );
    } on ApiException catch (e) {
      // Un 401 ya cerró la sesión (interceptor): no queda chat que mostrar.
      if (e.statusCode == 401) return;
      _fallido = peticion;
      mensajeError.value = e.mensaje;
    } finally {
      enviando.value = false;
    }
  }

  Future<void> _agregar(MensajeChat mensaje) async {
    mensajes.add(mensaje);
    if (mensajes.length > ChatRepository.maximo) mensajes.removeAt(0);
    await _repositorio.agregar(mensaje);
  }

  /// Elegir otra materia quita la ficha fijada si es de otra materia.
  void elegirMateria(String? codigo) {
    materia.value = codigo;
    final ficha = fichaContexto.value;
    if (ficha != null && ficha.materia != codigo) fichaContexto.value = null;
  }

  /// Desde el detalle: la ficha y su materia pasan a ser el contexto.
  void fijarFicha(FichaResumen ficha) {
    fichaContexto.value = ficha;
    materia.value = ficha.materia;
  }

  void quitarFicha() => fichaContexto.value = null;

  Future<void> borrarConversacion() async {
    await _repositorio.vaciar();
    mensajes.clear();
    mensajeError.value = '';
    _fallido = null;
  }

  /// Al cerrar sesión: el historial se borra del disco y se olvida el contexto.
  Future<void> cerrar() async {
    await _repositorio.borrarDelDisco();
    mensajes.clear();
    mensajeError.value = '';
    _fallido = null;
    materia.value = null;
    fichaContexto.value = null;
  }
}
