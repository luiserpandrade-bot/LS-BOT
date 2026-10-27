import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lsbot/utils/fechas.dart';

import 'apoyo/servidor_falso.dart';

const _token = 'tok-ana@ups.edu.ec';
const _ana = 'ana@ups.edu.ec';
const _luis = 'luis@ups.edu.ec';
const _opciones = 'Opciones de la duda';
const _vacio = 'Aún no hay dudas en esta ficha. ¡Sé el primero en preguntar!';

/// Abre la app con sesión y entra al detalle de la ficha 1.
Future<void> _abrirFicha(WidgetTester tester, ServidorFalso servidor) async {
  await abrirApp(tester, servidor, token: _token);
  await tocar(tester, find.text('Ancho de pistas en PCB'));
}

/// El detalle es una lista perezosa: hay que desplazarse para que las dudas
/// del final existan en el árbol.
Future<void> _bajarHasta(WidgetTester tester, Finder f) async {
  await tester.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
}

/// Abre el menú de la única duda propia visible y elige una opción.
Future<void> _elegirEnMenu(WidgetTester tester, String opcion) async {
  await _bajarHasta(tester, find.byTooltip(_opciones));
  await tocar(tester, find.byTooltip(_opciones));
  await tocar(tester, find.text(opcion));
}

void main() {
  late ServidorFalso servidor;

  setUp(() {
    reiniciarGetX();
    servidor = ServidorFalso();
  });
  tearDown(reiniciarGetX);

  test('la fecha se muestra legible en español', () {
    expect(fechaLegible(DateTime(2026, 10, 7, 9, 5)), '7 oct 2026, 09:05');
  });

  testWidgets('se ven las dudas de otros usuarios sin menú', (tester) async {
    servidor.dudas = [ServidorFalso.duda(1, 1, '¿Qué ancho necesita una pista de 2 A?', _luis, editada: true)];
    await _abrirFicha(tester, servidor);

    expect(servidor.peticionesDudas, ['GET /fichas/1/dudas']);
    await _bajarHasta(tester, find.text('¿Qué ancho necesita una pista de 2 A?'));
    expect(find.text('Dudas de la comunidad (1)'), findsOneWidget);
    expect(find.text('Luis'), findsOneWidget);
    expect(find.textContaining('· editada'), findsOneWidget);
    expect(find.byTooltip(_opciones), findsNothing);
  });

  testWidgets('con la lista vacía se ve el estado vacío', (tester) async {
    await _abrirFicha(tester, servidor);

    await _bajarHasta(tester, find.text(_vacio));
    expect(find.text('Dudas de la comunidad (0)'), findsOneWidget);
  });

  testWidgets('publicar agrega la duda y recarga la lista', (tester) async {
    await _abrirFicha(tester, servidor);

    await _bajarHasta(tester, find.text('Publicar duda'));
    await tocar(tester, find.text('Publicar duda'));
    await tester.enterText(campo('Tu duda'), '¿Sirve la misma regla en capas internas?');
    await tocar(tester, find.text('Publicar'));

    expect(servidor.peticionesDudas, ['GET /fichas/1/dudas', 'POST /fichas/1/dudas', 'GET /fichas/1/dudas']);
    expect(find.byType(BottomSheet), findsNothing);
    await _bajarHasta(tester, find.text('¿Sirve la misma regla en capas internas?'));
    expect(find.text('Dudas de la comunidad (1)'), findsOneWidget);
    expect(find.text(_vacio), findsNothing);
  });

  testWidgets('el formulario valida de 5 a 500 caracteres sin llamar al servidor', (tester) async {
    await _abrirFicha(tester, servidor);

    await _bajarHasta(tester, find.text('Publicar duda'));
    await tocar(tester, find.text('Publicar duda'));
    await tester.enterText(campo('Tu duda'), 'abc');
    await tocar(tester, find.text('Publicar'));

    expect(find.text('La duda debe tener entre 5 y 500 caracteres'), findsOneWidget);
    expect(servidor.peticionesDudas, ['GET /fichas/1/dudas']);
  });

  testWidgets('las dudas propias muestran Editar y Borrar; editar usa el formulario precargado', (tester) async {
    servidor.dudas = [ServidorFalso.duda(1, 1, 'Mi duda original', _ana)];
    await _abrirFicha(tester, servidor);

    await _bajarHasta(tester, find.byTooltip(_opciones));
    await tocar(tester, find.byTooltip(_opciones));
    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Borrar'), findsOneWidget);

    await tocar(tester, find.text('Editar'));
    expect(find.widgetWithText(TextFormField, 'Mi duda original'), findsOneWidget);

    await tester.enterText(campo('Tu duda'), 'Mi duda corregida');
    await tocar(tester, find.text('Guardar'));

    expect(servidor.peticionesDudas.sublist(1), ['PATCH /dudas/1', 'GET /fichas/1/dudas']);
    await _bajarHasta(tester, find.text('Mi duda corregida'));
    expect(find.textContaining('· editada'), findsOneWidget);
  });

  testWidgets('Borrar pide confirmación y Cancelar no borra', (tester) async {
    servidor.dudas = [ServidorFalso.duda(1, 1, 'Duda para borrar', _ana)];
    await _abrirFicha(tester, servidor);

    await _elegirEnMenu(tester, 'Borrar');
    expect(find.text('¿Borrar esta duda?'), findsOneWidget);
    await tocar(tester, find.text('Cancelar'));

    expect(servidor.peticionesDudas, ['GET /fichas/1/dudas']);
    expect(find.text('Duda para borrar'), findsOneWidget);

    await _elegirEnMenu(tester, 'Borrar');
    await tocar(tester, find.widgetWithText(FilledButton, 'Borrar'));

    expect(servidor.peticionesDudas.sublist(1), ['DELETE /dudas/1', 'GET /fichas/1/dudas']);
    expect(find.text('Duda para borrar'), findsNothing);
    expect(find.text('Duda borrada.'), findsOneWidget);
  });

  testWidgets('un 403 muestra el mensaje del servidor sin cerrar el formulario', (tester) async {
    servidor
      ..dudas = [ServidorFalso.duda(1, 1, 'Mi duda original', _ana)]
      ..codigoErrorDudas = 403;
    await _abrirFicha(tester, servidor);

    await _elegirEnMenu(tester, 'Editar');
    await tester.enterText(campo('Tu duda'), 'Mi duda corregida');
    await tocar(tester, find.text('Guardar'));

    expect(find.text('Solo el autor puede modificar o borrar esta duda'), findsOneWidget);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('Guardar'), findsOneWidget);
  });

  testWidgets('un 404 al borrar avisa y recarga la lista', (tester) async {
    servidor.dudas = [ServidorFalso.duda(1, 1, 'Duda ya borrada en otro equipo', _ana)];
    await _abrirFicha(tester, servidor);

    // Otra sesión la borra mientras esta pantalla sigue abierta.
    servidor.dudas = [];
    await _elegirEnMenu(tester, 'Borrar');
    await tocar(tester, find.widgetWithText(FilledButton, 'Borrar'));

    expect(servidor.peticionesDudas.sublist(1), ['DELETE /dudas/1', 'GET /fichas/1/dudas']);
    expect(find.text('La duda no existe'), findsOneWidget);
    expect(find.text('Duda ya borrada en otro equipo'), findsNothing);
    await _bajarHasta(tester, find.text(_vacio));
  });
}
