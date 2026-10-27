import 'package:get/get.dart';

import '../models/usuario.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/token_storage.dart';
import 'fichas_controller.dart';

/// Estado de la sesión de toda la app. `usuario` es null cuando no hay sesión.
class AuthController extends GetxController {
  AuthController({ApiClient? api, AuthService? servicio, TokenStorage? almacen})
    : _api = api ?? Get.find<ApiClient>(),
      _servicio = servicio ?? Get.find<AuthService>(),
      _almacen = almacen ?? Get.find<TokenStorage>();

  final ApiClient _api;
  final AuthService _servicio;
  final TokenStorage _almacen;

  final Rxn<Usuario> usuario = Rxn<Usuario>();
  final RxBool cargando = false.obs;

  /// `true` mientras se comprueba el token guardado al abrir la app.
  final RxBool restaurando = true.obs;

  /// Error del último intento de registro o inicio de sesión.
  final RxString mensajeError = ''.obs;

  /// Aviso en la pantalla de inicio de sesión (por ejemplo, sesión caducada).
  final RxString avisoSesion = ''.obs;

  bool get estaAutenticado => usuario.value != null;

  @override
  void onInit() {
    super.onInit();
    _api.alSesionCaducada = sesionCaducada;
    restaurarSesion();
  }

  /// Crea la cuenta y, si sale bien, inicia sesión. Devuelve `true` si entró.
  Future<bool> registrar(String email, String nombre, String password) async {
    cargando.value = true;
    mensajeError.value = '';
    try {
      await _servicio.registrar(email.trim(), nombre.trim(), password);
      await _entrar(email.trim(), password);
      return true;
    } on ApiException catch (e) {
      mensajeError.value = e.mensaje;
      return false;
    } finally {
      cargando.value = false;
    }
  }

  /// Pide el token, lo guarda en el almacenamiento seguro y carga el perfil.
  Future<bool> iniciarSesion(String email, String password) async {
    cargando.value = true;
    mensajeError.value = '';
    try {
      await _entrar(email.trim(), password);
      return true;
    } on ApiException catch (e) {
      mensajeError.value = e.mensaje;
      return false;
    } finally {
      cargando.value = false;
    }
  }

  Future<void> _entrar(String email, String password) async {
    final token = await _servicio.obtenerToken(email, password);
    _api.token = token;
    await _almacen.guardar(token);
    usuario.value = await _servicio.perfil();
    avisoSesion.value = '';
  }

  /// Al abrir la app: si hay un token guardado, comprueba con /usuarios/me
  /// que siga siendo válido. Un 401 borra el token; sin conexión se conserva
  /// (puede seguir siendo válido) y se avisa.
  Future<void> restaurarSesion() async {
    restaurando.value = true;
    try {
      final guardado = await _almacen.leer();
      if (guardado == null) return;
      _api.token = guardado;
      usuario.value = await _servicio.perfil();
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await cerrarSesion();
        avisoSesion.value = ApiException.mensajeSesionCaducada;
      } else {
        avisoSesion.value = e.mensaje;
      }
    } finally {
      restaurando.value = false;
    }
  }

  /// Lo llama el interceptor cuando el servidor responde 401 fuera del login.
  Future<void> sesionCaducada() async {
    if (!estaAutenticado) return;
    await cerrarSesion();
    avisoSesion.value = ApiException.mensajeSesionCaducada;
    // Si había una pantalla encima (por ejemplo, un detalle), se vuelve a la base.
    if (Get.key.currentState != null) Get.until((ruta) => ruta.isFirst);
  }

  /// Borra el token (seguro y en memoria) y el estado de las fichas: la
  /// próxima sesión crea un `FichasController` nuevo y carga desde cero.
  Future<void> cerrarSesion() async {
    await _almacen.borrar();
    _api.token = null;
    usuario.value = null;
    mensajeError.value = '';
    if (Get.isRegistered<FichasController>()) Get.delete<FichasController>(force: true);
  }
}
