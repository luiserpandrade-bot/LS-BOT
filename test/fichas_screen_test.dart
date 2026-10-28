import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoyo/servidor_falso.dart';

const _token = 'tok-ana@ups.edu.ec';

void main() {
  late ServidorFalso servidor;

  setUp(() {
    reiniciarGetX();
    servidor = ServidorFalso();
  });
  tearDown(reiniciarGetX);

  testWidgets('la lista de fichas muestra los elementos', (tester) async {
    await abrirApp(tester, servidor, token: _token);

    expect(find.text('Ancho de pistas en PCB'), findsOneWidget);
    expect(find.text('PWM con Timer2'), findsOneWidget);
    expect(find.text('DE-T05'), findsOneWidget);
    expect(find.text('IPC-2221B'), findsOneWidget);
    final pedido = servidor.peticionesFichas.single;
    expect(pedido.headers['Authorization'], 'Bearer $_token');
    expect(pedido.queryParameters, isEmpty);
  });

  testWidgets('con la lista vacía se ve el estado vacío', (tester) async {
    servidor.fichas = [];
    await abrirApp(tester, servidor, token: _token);

    expect(find.text('No hay fichas'), findsOneWidget);
    expect(find.text('Todavía no hay fichas publicadas.'), findsOneWidget);
  });

  testWidgets('con error se ve el estado de error y Reintentar vuelve a cargar', (tester) async {
    servidor
      ..codigoErrorFichas = 500
      ..fallasFichas = 1;
    await abrirApp(tester, servidor, token: _token);

    expect(find.text('El servidor tuvo un problema. Inténtalo más tarde.'), findsOneWidget);
    expect(servidor.peticionesFichas, hasLength(1));

    await tocar(tester, find.text('Reintentar'));

    expect(servidor.peticionesFichas, hasLength(2));
    expect(find.text('Reintentar'), findsNothing);
    expect(find.text('PWM con Timer2'), findsOneWidget);
  });

  testWidgets('filtrar por materia envía el parámetro correcto', (tester) async {
    await abrirApp(tester, servidor, token: _token);

    await tocar(tester, find.widgetWithText(ChoiceChip, 'Sistemas Digitales I'));

    expect(servidor.peticionesFichas.last.queryParameters, {'materia': 'sistemas_digitales_1'});
    expect(find.text('PWM con Timer2'), findsOneWidget);
    expect(find.text('Ancho de pistas en PCB'), findsNothing);

    await tocar(tester, find.widgetWithText(ChoiceChip, 'Todas'));
    expect(servidor.peticionesFichas.last.queryParameters, isEmpty);
  });

  testWidgets('la búsqueda envía q después de dejar de escribir', (tester) async {
    await abrirApp(tester, servidor, token: _token);

    await tester.enterText(find.byType(TextField).first, 'vhdl');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(servidor.peticionesFichas.last.queryParameters, {'q': 'vhdl'});
    expect(find.text('Introducción a VHDL'), findsOneWidget);
    expect(find.text('PWM con Timer2'), findsNothing);
  });

  testWidgets('tocar una ficha abre su detalle con normas como chips', (tester) async {
    await abrirApp(tester, servidor, token: _token);

    await tocar(tester, find.text('Ancho de pistas en PCB'));

    // El detalle pide la ficha y, en paralelo, sus dudas.
    expect(servidor.peticiones.map((o) => o.path), containsAll(['/fichas/1', '/fichas/1/dudas']));
    expect(find.text('Ideas clave'), findsOneWidget);
    expect(find.text('Preguntas de refuerzo'), findsOneWidget);
    expect(find.widgetWithText(Chip, 'IPC-2221B'), findsOneWidget);
  });

  testWidgets('la pestaña LS-bot abre el chat con tres preguntas sugeridas', (tester) async {
    await abrirApp(tester, servidor, token: _token);

    await tocar(tester, find.widgetWithText(NavigationDestination, 'LS-bot'));
    expect(find.text('Disponible en la siguiente versión'), findsNothing);
    expect(find.text('¡Hola! Soy LS-bot'), findsOneWidget);
    expect(find.byType(ActionChip), findsNWidgets(3));

    await tocar(tester, find.widgetWithText(NavigationDestination, 'Fichas'));
    expect(find.text('Fichas de estudio'), findsOneWidget);
  });
}
