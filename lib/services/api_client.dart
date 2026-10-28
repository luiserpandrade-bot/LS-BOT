import 'package:dio/dio.dart';

import '../config/api_config.dart';
import 'api_exception.dart';

export 'api_exception.dart';

/// Cliente HTTP único de la app: una instancia de `dio` con la dirección del
/// backend, 15 segundos de espera máxima y dos interceptores. No registra
/// peticiones: así ningún token ni contraseña termina en los registros.
class ApiClient {
  ApiClient({Dio? dio})
    : dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: const Duration(seconds: 15),
              sendTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
            ),
          ) {
    // Agrega `Authorization: Bearer <token>` a toda petición cuando hay sesión.
    this.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (opciones, siguiente) {
          final t = token;
          if (t != null) opciones.headers['Authorization'] = 'Bearer $t';
          siguiente.next(opciones);
        },
      ),
    );

    // Un 401 fuera del login significa que el token caducó: se avisa en un
    // solo lugar. En el login, un 401 solo es «contraseña incorrecta».
    this.dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, siguiente) {
          final esLogin = error.requestOptions.path == ApiException.rutaLogin;
          if (error.response?.statusCode == 401 && !esLogin) {
            alSesionCaducada?.call();
          }
          siguiente.next(error);
        },
      ),
    );
  }

  final Dio dio;

  /// Token JWT de la sesión actual, en memoria mientras la app está abierta.
  String? token;

  /// Lo asigna `AuthController`: se llama cuando el servidor responde 401.
  void Function()? alSesionCaducada;

  Future<Response<dynamic>> get(String ruta, {Map<String, dynamic>? query}) =>
      _enviar(() => dio.get(ruta, queryParameters: query));

  /// `tiempoRecepcion` amplía la espera solo en esa petición (la IA del
  /// asistente puede tardar más que el resto de la API).
  Future<Response<dynamic>> post(String ruta, {Object? data, bool formulario = false, Duration? tiempoRecepcion}) =>
      _enviar(
        () => dio.post(
          ruta,
          data: data,
          options: Options(
            contentType: formulario ? Headers.formUrlEncodedContentType : null,
            receiveTimeout: tiempoRecepcion,
          ),
        ),
      );

  Future<Response<dynamic>> patch(String ruta, {Object? data}) => _enviar(() => dio.patch(ruta, data: data));

  Future<Response<dynamic>> delete(String ruta) => _enviar(() => dio.delete(ruta));

  /// Único try/catch: todo error de `dio` sale como `ApiException`.
  Future<Response<dynamic>> _enviar(Future<Response<dynamic>> Function() peticion) async {
    try {
      return await peticion();
    } on DioException catch (e) {
      throw ApiException.desde(e);
    }
  }
}
