import '../models/usuario.dart';
import 'api_client.dart';

/// Registro, inicio de sesión y perfil contra `/usuarios`.
class AuthService {
  AuthService(this._api);

  final ApiClient _api;

  /// POST /usuarios/ con JSON. Correo repetido → 400 con el motivo en `detail`.
  Future<Usuario> registrar(String email, String nombre, String password) async {
    final r = await _api.post('/usuarios/', data: {'email': email, 'nombre': nombre, 'password': password});
    return Usuario.fromJson(Map<String, dynamic>.from(r.data as Map));
  }

  /// POST /usuarios/token: formulario `x-www-form-urlencoded` (OAuth2), no
  /// JSON. El campo se llama `username` pero lleva el correo.
  Future<String> obtenerToken(String email, String password) async {
    final r = await _api.post(
      ApiException.rutaLogin,
      data: {'username': email, 'password': password},
      formulario: true,
    );
    return (r.data as Map)['access_token'] as String;
  }

  /// GET /usuarios/me.
  Future<Usuario> perfil() async {
    final r = await _api.get('/usuarios/me');
    return Usuario.fromJson(Map<String, dynamic>.from(r.data as Map));
  }
}
