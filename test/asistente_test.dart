import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:lsbot/controllers/asistente_controller.dart';
import 'package:lsbot/models/mensaje_chat.dart';
import 'package:lsbot/models/respuesta_asistente.dart';
import 'package:lsbot/repositories/chat_repository.dart';
import 'package:lsbot/services/asistente_service.dart';

import 'apoyo/servidor_falso.dart';

const _token = 'tok-ana@ups.edu.ec';
const _aviso = 'Sugerencia de IA: verifica con tu docente';

Finder get _pestanaLsBot => find.widgetWithText(NavigationDestination, 'LS-bot');
Finder get _campo => find.widgetWithText(TextField, 'Escribe tu pregunta');

/// Abre la app con sesión y entra a la pestaña LS-bot.
Future<void> _abrirLsBot(WidgetTester tester, ServidorFalso servidor) async {
  await abrirApp(tester, servidor, token: _token);
  await tocar(tester, _pestanaLsBot);
}

Future<void> _preguntar(WidgetTester tester, String texto) async {
  await tester.enterText(_campo, texto);
  await tocar(tester, find.byTooltip('Enviar'));
}

void main() {
  late ServidorFalso servidor;

  setUp(() {
    reiniciarGetX();
    servidor = ServidorFalso();
  });
  tearDown(reiniciarGetX);

  testWidgets('enviar una pregunta muestra la respuesta y sus fuentes; la fuente abre su detalle', (tester) async {
    await _abrirLsBot(tester, servidor);

    await _preguntar(tester, '¿Qué ancho de pista uso?');

    expect(find.text('¿Qué ancho de pista uso?'), findsOneWidget);
    expect(find.text('Respuesta de prueba según [DE-T05].'), findsOneWidget);
    expect(find.text(_aviso), findsOneWidget);
    expect(find.text('· modo reglas'), findsNothing);
    final cuerpo = servidor.peticionesAsistente.single;
    expect(cuerpo, {'pregunta': '¿Qué ancho de pista uso?'});
    expect(servidor.peticiones.last.receiveTimeout, AsistenteService.tiempoRecepcion);

    await tocar(tester, find.widgetWithText(ActionChip, 'DE-T05 · Ancho de pistas en PCB'));
    expect(find.text('Ideas clave'), findsOneWidget);
    expect(servidor.peticiones.map((o) => o.path), contains('/fichas/1'));
  });

  testWidgets('el estado vacío saluda y una pregunta sugerida se envía', (tester) async {
    await _abrirLsBot(tester, servidor);
    expect(find.text('¡Hola! Soy LS-bot'), findsOneWidget);

    await tocar(tester, find.widgetWithText(ActionChip, '¿Cómo calculo el periodo del PWM con Timer2?'));

    expect(servidor.peticionesAsistente.single['pregunta'], '¿Cómo calculo el periodo del PWM con Timer2?');
    expect(find.text('¡Hola! Soy LS-bot'), findsNothing);
    expect(find.text('Respuesta de prueba según [DE-T05].'), findsOneWidget);
  });

  testWidgets('el modo reglas muestra su marca', (tester) async {
    servidor.modoAsistente = 'reglas';
    await _abrirLsBot(tester, servidor);

    await _preguntar(tester, '¿Qué es un RTOS?');
    expect(find.text('· modo reglas'), findsOneWidget);
    expect(find.text(_aviso), findsOneWidget);
  });

  testWidgets('un 429 muestra el límite gratuito con Reintentar, y Reintentar vuelve a enviar', (tester) async {
    servidor
      ..codigoErrorAsistente = 429
      ..fallasAsistente = 1;
    await _abrirLsBot(tester, servidor);

    await _preguntar(tester, '¿Qué es un RTOS?');
    expect(find.textContaining('límite gratuito'), findsOneWidget);

    await tocar(tester, find.text('Reintentar'));
    expect(servidor.peticionesAsistente, hasLength(2));
    expect(servidor.peticionesAsistente.last['pregunta'], '¿Qué es un RTOS?');
    expect(find.textContaining('límite gratuito'), findsNothing);
    expect(find.text('Respuesta de prueba según [DE-T05].'), findsOneWidget);
    // La pregunta no se repite en el chat.
    expect(find.text('¿Qué es un RTOS?'), findsOneWidget);
  });

  testWidgets('un 502 muestra el mensaje del servidor con Reintentar', (tester) async {
    servidor
      ..codigoErrorAsistente = 502
      ..fallasAsistente = 1;
    await _abrirLsBot(tester, servidor);

    await _preguntar(tester, '¿Qué es un RTOS?');
    expect(find.text('El servidor no pudo comunicarse con el servicio de IA.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('sin conexión muestra su mensaje con Reintentar', (tester) async {
    await _abrirLsBot(tester, servidor);
    servidor.sinConexion = true;

    await _preguntar(tester, '¿Qué es un RTOS?');
    expect(find.textContaining('No hay conexión con el servidor'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('una pregunta de menos de 3 caracteres no llega al servidor', (tester) async {
    await _abrirLsBot(tester, servidor);

    await _preguntar(tester, 'hi');
    expect(find.text('La pregunta debe tener entre 3 y 500 caracteres'), findsOneWidget);
    expect(servidor.peticionesAsistente, isEmpty);
  });

  testWidgets('desde el detalle de una ficha se fija el contexto y se envía ficha_id', (tester) async {
    await abrirApp(tester, servidor, token: _token);

    await tocar(tester, find.text('PWM con Timer2'));
    await tocar(tester, find.text('Preguntar a LS-bot sobre esta ficha'));

    expect(find.text('Contexto: SD1-S14 PWM con Timer2'), findsOneWidget);
    await _preguntar(tester, '¿Cómo calculo el periodo?');
    final cuerpo = servidor.peticionesAsistente.single;
    expect(cuerpo['ficha_id'], 2);
    expect(cuerpo['materia'], 'sistemas_digitales_1');
    expect(find.widgetWithText(ActionChip, 'SD1-S14 · PWM con Timer2'), findsOneWidget);

    await tocar(tester, find.byTooltip('Quitar contexto'));
    expect(find.textContaining('Contexto:'), findsNothing);
    await _preguntar(tester, '¿Y el preescalador?');
    expect(servidor.peticionesAsistente.last.containsKey('ficha_id'), isFalse);
  });

  testWidgets('Borrar conversación pide confirmación y vacía el chat', (tester) async {
    await _abrirLsBot(tester, servidor);
    await _preguntar(tester, '¿Qué es un RTOS?');

    await tocar(tester, find.byTooltip('Borrar conversación'));
    await tocar(tester, find.text('Cancelar'));
    expect(find.text('¿Qué es un RTOS?'), findsOneWidget);

    await tocar(tester, find.byTooltip('Borrar conversación'));
    await tocar(tester, find.widgetWithText(FilledButton, 'Borrar'));
    expect(find.text('¿Qué es un RTOS?'), findsNothing);
    expect(find.text('¡Hola! Soy LS-bot'), findsOneWidget);
    expect(Hive.box<Map>('chat_1').isEmpty, isTrue);
  });

  testWidgets('cerrar sesión borra el historial del chat', (tester) async {
    await _abrirLsBot(tester, servidor);
    await _preguntar(tester, '¿Qué es un RTOS?');
    expect(Hive.box<Map>('chat_1').length, 2);

    await tocar(tester, find.widgetWithText(NavigationDestination, 'Perfil'));
    await tocar(tester, find.text('Cerrar sesión'));

    expect(find.text('Iniciar sesión'), findsWidgets);
    expect(Hive.isBoxOpen('chat_1'), isFalse);
    expect(Get.find<AsistenteController>().mensajes, isEmpty);
  });

  test('el historial sigue tras cerrar y volver a abrir la caja, con un máximo de 50', () async {
    await prepararHive();
    final antes = ChatRepository();
    await antes.abrirParaUsuario(7);
    for (var i = 0; i < 52; i++) {
      await antes.agregar(MensajeChat(rol: RolMensaje.usuario, texto: 'Pregunta $i', fecha: DateTime(2026, 10, 27)));
    }
    await antes.agregar(
      MensajeChat(
        rol: RolMensaje.bot,
        texto: 'Respuesta',
        fecha: DateTime(2026, 10, 27, 12),
        modo: 'reglas',
        fuentes: const [FuenteAsistente(id: 2, codigo: 'SD1-S14', titulo: 'PWM con Timer2')],
      ),
    );
    // Simula el cierre completo de la app.
    await Hive.close();

    final despues = ChatRepository();
    await despues.abrirParaUsuario(7);
    final lista = despues.listar();
    expect(lista, hasLength(ChatRepository.maximo));
    expect(lista.first.texto, 'Pregunta 3');
    expect(lista.last.rol, RolMensaje.bot);
    expect(lista.last.esModoReglas, isTrue);
    expect(lista.last.fecha, DateTime(2026, 10, 27, 12));
    expect(lista.last.fuentes.single.codigo, 'SD1-S14');
    expect(lista.last.fuentes.single.titulo, 'PWM con Timer2');

    await despues.borrarDelDisco();
  });

  test('borrar del disco elimina la caja de chat de esa persona', () async {
    await prepararHive();
    final repositorio = ChatRepository();
    await repositorio.abrirParaUsuario(8);
    await repositorio.agregar(MensajeChat(rol: RolMensaje.usuario, texto: 'Hola', fecha: DateTime(2026)));
    expect(await Hive.boxExists('chat_8'), isTrue);

    await repositorio.borrarDelDisco();
    expect(await Hive.boxExists('chat_8'), isFalse);
    expect(repositorio.listar(), isEmpty);
  });
}
