import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lsbot/main.dart';
import 'package:lsbot/services/api_client.dart';
import 'package:lsbot/services/token_storage.dart';

/// Servidor falso que imita el contrato del backend de LS-bot (usuarios,
/// token con formulario, materias y fichas con `detail` en los errores).
/// No necesita el backend ni el emulador.
class ServidorFalso implements HttpClientAdapter {
  final usuarios = <String, ({String nombre, String clave})>{
    'ana@ups.edu.ec': (nombre: 'Ana', clave: 'clave12345'),
    'luis@ups.edu.ec': (nombre: 'Luis', clave: 'clave67890'),
  };
  List<Map<String, dynamic>> fichas = [
    ficha(1, 'DE-T05', 'diseno_electronico', 'Diseño Electrónico', 'Ancho de pistas en PCB', ['IPC-2221B']),
    ficha(2, 'SD1-S14', 'sistemas_digitales_1', 'Sistemas Digitales I', 'PWM con Timer2', []),
    ficha(3, 'SD2-S01', 'sistemas_digitales_2', 'Sistemas Digitales II', 'Introducción a VHDL', ['IEEE 1076']),
  ];

  /// Peticiones recibidas, en orden (para revisar rutas y parámetros).
  final peticiones = <RequestOptions>[];

  /// Si tiene valor, GET /fichas/ responde ese código las próximas
  /// `fallasFichas` veces.
  int? codigoErrorFichas;
  int fallasFichas = 0;

  /// Dudas guardadas; `autor_email` decide `es_mia` según el token.
  List<Map<String, dynamic>> dudas = [];
  int _siguienteDuda = 100;

  /// Si tiene valor, el próximo PATCH o DELETE de una duda responde ese código.
  int? codigoErrorDudas;

  static Map<String, dynamic> duda(int id, int fichaId, String texto, String autorEmail, {bool editada = false}) => {
    'id': id,
    'ficha_id': fichaId,
    'texto': texto,
    'autor_email': autorEmail,
    'creado': '2026-10-20T15:30:00Z',
    'editado': editada ? '2026-10-21T09:00:00Z' : null,
  };

  static Map<String, dynamic> ficha(
    int id,
    String codigo,
    String materia,
    String materiaNombre,
    String titulo,
    List<String> normas,
  ) => {
    'id': id,
    'codigo': codigo,
    'materia': materia,
    'materia_nombre': materiaNombre,
    'unidad': 1,
    'unidad_nombre': 'Fundamentos',
    'sesion': 'S1',
    'titulo': titulo,
    'normas': normas,
  };

  Iterable<RequestOptions> get peticionesFichas => peticiones.where((o) => o.path == '/fichas/');

  /// Peticiones a las dudas como «MÉTODO ruta», por ejemplo `POST /fichas/1/dudas`.
  List<String> get peticionesDudas =>
      peticiones.where((o) => o.path.contains('dudas')).map((o) => '${o.method} ${o.path}').toList();

  /// Igual que `DudaSalida` del backend: autor por nombre y `es_mia`.
  Map<String, dynamic> _dudaSalida(Map<String, dynamic> d, String email) => {
    'id': d['id'],
    'ficha_id': d['ficha_id'],
    'texto': d['texto'],
    'autor': usuarios[d['autor_email']]!.nombre,
    'es_mia': d['autor_email'] == email,
    'creado': d['creado'],
    'editado': d['editado'],
  };

  /// Mismas reglas que `DudaEntrada`: de 5 a 500 caracteres.
  ResponseBody? _validarDuda(String texto) {
    final t = (jsonDecode(texto) as Map)['texto'] as String? ?? '';
    if (t.length < 5 || t.length > 500) {
      return _error('Datos inválidos — texto: String should have at least 5 characters', 422);
    }
    return null;
  }

  ResponseBody _json(Object cuerpo, int codigo) => ResponseBody.fromString(
    jsonEncode(cuerpo),
    codigo,
    headers: {
      Headers.contentTypeHeader: ['application/json; charset=utf-8'],
    },
  );

  ResponseBody _error(String detail, int codigo) => _json({'detail': detail}, codigo);

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? cuerpo, Future<void>? cancelar) async {
    peticiones.add(o);
    final texto = cuerpo == null ? '' : utf8.decode((await cuerpo.toList()).expand((x) => x).toList());
    final ruta = o.path;

    if (ruta == '/usuarios/' && o.method == 'POST') {
      final b = jsonDecode(texto) as Map;
      final email = b['email'] as String;
      if (usuarios.containsKey(email)) return _error('El email $email ya está registrado', 400);
      usuarios[email] = (nombre: b['nombre'] as String, clave: b['password'] as String);
      return _json({'id': usuarios.length, 'email': email, 'nombre': b['nombre']}, 201);
    }
    if (ruta == '/usuarios/token') {
      if (!'${o.contentType}'.contains('application/x-www-form-urlencoded')) {
        return _error('Datos inválidos — username: Field required', 422);
      }
      final campos = Uri.splitQueryString(texto);
      if (usuarios[campos['username']]?.clave != campos['password']) {
        return _error('Email o contraseña incorrectos', 401);
      }
      return _json({'access_token': 'tok-${campos['username']}', 'token_type': 'bearer'}, 200);
    }

    // Desde aquí todo exige token.
    final auth = o.headers['Authorization'];
    final email = auth is String && auth.startsWith('Bearer tok-') ? auth.substring('Bearer tok-'.length) : null;
    final usuario = usuarios[email];
    if (usuario == null) return _error('No se pudo validar las credenciales', 401);

    if (ruta == '/usuarios/me') return _json({'id': 1, 'email': email!, 'nombre': usuario.nombre}, 200);
    if (ruta == '/fichas/materias') {
      return _json([
        {'materia': 'diseno_electronico', 'materia_nombre': 'Diseño Electrónico', 'total_fichas': 14},
        {'materia': 'sistemas_digitales_1', 'materia_nombre': 'Sistemas Digitales I', 'total_fichas': 25},
        {'materia': 'sistemas_digitales_2', 'materia_nombre': 'Sistemas Digitales II', 'total_fichas': 25},
      ], 200);
    }
    if (ruta == '/fichas/') {
      if (codigoErrorFichas != null && fallasFichas > 0) {
        fallasFichas--;
        return _error('Error interno del servidor. Inténtalo más tarde.', codigoErrorFichas!);
      }
      final materia = o.queryParameters['materia'];
      final q = (o.queryParameters['q'] as String?)?.toLowerCase();
      final lista = fichas
          .where((f) => materia == null || f['materia'] == materia)
          .where((f) => q == null || (f['titulo'] as String).toLowerCase().contains(q))
          .toList();
      return _json(lista, 200);
    }
    final m = RegExp(r'^/fichas/(\d+)$').firstMatch(ruta);
    if (m != null) {
      final id = int.parse(m.group(1)!);
      final f = fichas.where((f) => f['id'] == id).firstOrNull;
      if (f == null) return _error('La ficha no existe', 404);
      return _json({
        ...f,
        'silabo': 'Unidad 1',
        'ideas_clave': ['Idea uno'],
        'formulas': ['P = V · I'],
        'preguntas': ['¿Por qué?'],
        'fuente': 'Redacción propia',
        'total_dudas': dudas.where((d) => d['ficha_id'] == id).length,
      }, 200);
    }
    final enFicha = RegExp(r'^/fichas/(\d+)/dudas$').firstMatch(ruta);
    if (enFicha != null) {
      final fichaId = int.parse(enFicha.group(1)!);
      if (!fichas.any((f) => f['id'] == fichaId)) return _error('La ficha no existe', 404);
      if (o.method == 'POST') {
        final invalida = _validarDuda(texto);
        if (invalida != null) return invalida;
        final nueva = duda(_siguienteDuda++, fichaId, ((jsonDecode(texto) as Map)['texto'] as String).trim(), email!)
          ..['creado'] = '2026-10-27T12:00:00Z';
        dudas.insert(0, nueva);
        return _json(_dudaSalida(nueva, email), 201);
      }
      return _json([for (final d in dudas.where((d) => d['ficha_id'] == fichaId)) _dudaSalida(d, email!)], 200);
    }
    final unaDuda = RegExp(r'^/dudas/(\d+)$').firstMatch(ruta);
    if (unaDuda != null) {
      if (codigoErrorDudas != null) {
        final codigo = codigoErrorDudas!;
        codigoErrorDudas = null;
        return _error(codigo == 403 ? 'Solo el autor puede modificar o borrar esta duda' : 'Error forzado', codigo);
      }
      final id = int.parse(unaDuda.group(1)!);
      final d = dudas.where((d) => d['id'] == id).firstOrNull;
      if (d == null) return _error('La duda no existe', 404);
      if (d['autor_email'] != email) return _error('Solo el autor puede modificar o borrar esta duda', 403);
      if (o.method == 'DELETE') {
        dudas.remove(d);
        return ResponseBody.fromString('', 204);
      }
      final invalida = _validarDuda(texto);
      if (invalida != null) return invalida;
      d
        ..['texto'] = ((jsonDecode(texto) as Map)['texto'] as String).trim()
        ..['editado'] = '2026-10-27T13:00:00Z';
      return _json(_dudaSalida(d, email!), 200);
    }
    return _error('Not Found', 404);
  }

  @override
  void close({bool force = false}) {}
}

/// Cliente con el servidor falso como adaptador.
ApiClient clienteFalso(HttpClientAdapter servidor) =>
    ApiClient(dio: Dio(BaseOptions(baseUrl: 'http://falso'))..httpClientAdapter = servidor);

/// Abre la app completa contra el servidor falso. Con `token`, empieza con
/// una sesión guardada (como si la persona ya hubiera entrado antes).
Future<void> abrirApp(WidgetTester tester, ServidorFalso servidor, {String? token}) async {
  FlutterSecureStorage.setMockInitialValues({'access_token': ?token});
  registrarDependencias(api: clienteFalso(servidor), almacen: TokenStorage());
  await tester.pumpWidget(const LsBotApp());
  await tester.pumpAndSettle();
}

/// Entre pruebas, GetX debe empezar de cero.
void reiniciarGetX() {
  Get.reset();
  Get.testMode = true;
}

/// Desplaza hasta el widget antes de tocarlo.
Future<void> tocar(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.tap(f);
  await tester.pumpAndSettle();
}

/// Para escribir en un campo identificado por su etiqueta.
Finder campo(String etiqueta) => find.widgetWithText(TextFormField, etiqueta);
