import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lsbot/services/api_client.dart';

import 'apoyo/servidor_falso.dart';

/// Adaptador que responde siempre el mismo código con un `detail`, o que
/// falla como si no hubiera red.
class _Respuesta implements HttpClientAdapter {
  _Respuesta(this.codigo, [this.detail]);
  _Respuesta.sinConexion() : codigo = 0, detail = null;

  final int codigo;
  final String? detail;

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? cuerpo, Future<void>? cancelar) async {
    if (codigo == 0) throw const SocketException('Connection refused');
    return ResponseBody.fromString(
      jsonEncode({'detail': detail}),
      codigo,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Future<ApiException> _error(HttpClientAdapter adaptador, {String ruta = '/fichas/'}) async {
  try {
    await clienteFalso(adaptador).get(ruta);
  } on ApiException catch (e) {
    return e;
  }
  fail('Se esperaba una ApiException');
}

void main() {
  test('400, 401, 422, 500 y sin conexión dan mensajes distintos en español', () async {
    final e400 = await _error(_Respuesta(400, 'El email ana@ups.edu.ec ya está registrado'));
    final e401 = await _error(_Respuesta(401, 'No se pudo validar las credenciales'));
    final e422 = await _error(_Respuesta(422, 'Datos inválidos — password: muy corta'));
    final e500 = await _error(_Respuesta(500, 'Error interno del servidor. Inténtalo más tarde.'));
    final sinRed = await _error(_Respuesta.sinConexion());

    expect(e400.mensaje, 'El email ana@ups.edu.ec ya está registrado');
    expect(e400.statusCode, 400);
    expect(e401.mensaje, ApiException.mensajeSesionCaducada);
    expect(e401.statusCode, 401);
    expect(e422.mensaje, 'Datos inválidos — password: muy corta');
    expect(e500.mensaje, ApiException.mensajeServidor);
    expect(sinRed.mensaje, ApiException.mensajeSinConexion);
    expect(sinRed.statusCode, isNull);

    final mensajes = {e400.mensaje, e401.mensaje, e422.mensaje, e500.mensaje, sinRed.mensaje};
    expect(mensajes, hasLength(5));
  });

  test('403, 404, 429 y 503 también tienen su propio mensaje', () async {
    final e403 = await _error(_Respuesta(403, 'Solo el autor puede modificar o borrar esta duda'));
    final e404 = await _error(_Respuesta(404, 'La ficha no existe'));
    final e429 = await _error(_Respuesta(429, 'Límite'));
    final e503 = await _error(_Respuesta(503));

    expect(e403.mensaje, 'Solo el autor puede modificar o borrar esta duda');
    expect((await _error(_Respuesta(403))).mensaje, ApiException.mensajeSinPermiso);
    expect(e404.mensaje, 'La ficha no existe');
    expect(e429.mensaje, ApiException.mensajeDemasiadas);
    expect(e503.mensaje, ApiException.mensajeServidor);
  });

  test('en el login, un 401 muestra el detail del servidor', () async {
    final e = await _error(_Respuesta(401, 'Email o contraseña incorrectos'), ruta: ApiException.rutaLogin);
    expect(e.mensaje, 'Email o contraseña incorrectos');
  });

  test('tiempo agotado tiene su propio mensaje', () {
    final e = ApiException.desde(
      DioException(
        requestOptions: RequestOptions(path: '/fichas/'),
        type: DioExceptionType.receiveTimeout,
      ),
    );
    expect(e.mensaje, ApiException.mensajeTiempoAgotado);
  });

  test('un 401 fuera del login avisa que la sesión caducó; en el login no', () async {
    var avisos = 0;
    final cliente = clienteFalso(_Respuesta(401, 'x'))..alSesionCaducada = () => avisos++;
    await expectLater(cliente.get('/fichas/'), throwsA(isA<ApiException>()));
    await expectLater(cliente.post(ApiException.rutaLogin, formulario: true), throwsA(isA<ApiException>()));
    expect(avisos, 1);
  });
}
