import 'dart:io';

import 'package:dio/dio.dart';

/// Error de red o HTTP ya traducido a un mensaje en español para la persona.
/// `statusCode` es null cuando el fallo no vino de una respuesta HTTP
/// (sin conexión, tiempo agotado).
class ApiException implements Exception {
  ApiException(this.mensaje, {this.statusCode});

  final String mensaje;
  final int? statusCode;

  static const rutaLogin = '/usuarios/token';

  static const mensajeSinConexion = 'No hay conexión con el servidor. Revisa tu red y que el backend esté encendido.';
  static const mensajeTiempoAgotado = 'El servidor tardó demasiado en responder. Inténtalo de nuevo.';
  static const mensajeSesionCaducada = 'Tu sesión caducó. Inicia sesión de nuevo.';
  static const mensajeSinPermiso = 'No tienes permiso para realizar esta acción.';
  static const mensajeNoEncontrado = 'No se encontró lo que buscabas.';
  static const mensajeDemasiadas = 'Hiciste demasiadas solicitudes seguidas. Espera un momento e inténtalo de nuevo.';
  static const mensajeServidor = 'El servidor tuvo un problema. Inténtalo más tarde.';
  static const mensajeSolicitudInvalida = 'La solicitud no es válida. Revisa los datos.';
  static const mensajeDatosInvalidos = 'Algunos datos no son válidos. Revisa el formulario.';

  /// Único lugar donde un error de `dio` se convierte en texto para la persona.
  factory ApiException.desde(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(mensajeTiempoAgotado);
      case DioExceptionType.badResponse:
        return _desdeRespuesta(e.response!, e.requestOptions.path);
      default:
        if (e.type == DioExceptionType.connectionError || e.error is SocketException) {
          return ApiException(mensajeSinConexion);
        }
        return ApiException('No se pudo completar la solicitud. Inténtalo de nuevo.');
    }
  }

  static ApiException _desdeRespuesta(Response<dynamic> r, String ruta) {
    final codigo = r.statusCode ?? 0;
    final datos = r.data;
    final detail = datos is Map && datos['detail'] is String ? datos['detail'] as String : null;
    switch (codigo) {
      case 400:
        return ApiException(detail ?? mensajeSolicitudInvalida, statusCode: codigo);
      case 401:
        // En el login un 401 significa «credenciales incorrectas»; en cualquier
        // otra ruta, que el token ya no sirve.
        if (ruta == rutaLogin && detail != null) return ApiException(detail, statusCode: codigo);
        return ApiException(mensajeSesionCaducada, statusCode: codigo);
      case 403:
        return ApiException(detail ?? mensajeSinPermiso, statusCode: codigo);
      case 404:
        return ApiException(detail ?? mensajeNoEncontrado, statusCode: codigo);
      case 422:
        // El backend ya entrega `detail` como texto («Datos inválidos — campo: …»).
        return ApiException(detail ?? mensajeDatosInvalidos, statusCode: codigo);
      case 429:
        return ApiException(mensajeDemasiadas, statusCode: codigo);
    }
    if (codigo >= 500) return ApiException(mensajeServidor, statusCode: codigo);
    return ApiException('La solicitud no pudo completarse (código $codigo).', statusCode: codigo);
  }

  @override
  String toString() => mensaje;
}
