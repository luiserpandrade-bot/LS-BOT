import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lsbot/models/ficha_resumen.dart';
import 'package:lsbot/repositories/favoritos_repository.dart';
import 'package:lsbot/utils/fechas.dart';

import 'apoyo/servidor_falso.dart';

const _token = 'tok-ana@ups.edu.ec';
const _vacio = 'Aún no tienes fichas favoritas';

Finder get _pestanaFavoritos => find.widgetWithText(NavigationDestination, 'Favoritos');

void main() {
  late ServidorFalso servidor;

  setUp(() {
    reiniciarGetX();
    servidor = ServidorFalso();
  });
  tearDown(reiniciarGetX);

  test('la fecha corta se muestra como dd/mm hh:mm', () {
    expect(fechaCorta(DateTime(2026, 3, 7, 9, 5)), '07/03 09:05');
  });

  testWidgets('marcar una ficha la agrega a Favoritos y quitarla la elimina', (tester) async {
    await abrirApp(tester, servidor, token: _token);

    await tocar(tester, find.byTooltip('Agregar a favoritos').first);
    expect(find.byTooltip('Quitar de favoritos'), findsOneWidget);

    await tocar(tester, _pestanaFavoritos);
    expect(find.text('Ancho de pistas en PCB'), findsOneWidget);
    expect(find.text(_vacio), findsNothing);

    await tocar(tester, find.byTooltip('Quitar de favoritos'));
    expect(find.text(_vacio), findsOneWidget);
    expect(Hive.box<Map>('favoritos_1').isEmpty, isTrue);
  });

  testWidgets('el marcador del detalle agrega la ficha a Favoritos', (tester) async {
    await abrirApp(tester, servidor, token: _token);

    await tocar(tester, find.text('PWM con Timer2'));
    await tocar(tester, find.byTooltip('Agregar a favoritos'));
    expect(find.byTooltip('Quitar de favoritos'), findsOneWidget);
    expect(Hive.box<Map>('favoritos_1').containsKey(2), isTrue);
  });

  testWidgets('la pestaña Favoritos sin fichas muestra el estado vacío y lleva a Fichas', (tester) async {
    await abrirApp(tester, servidor, token: _token);

    await tocar(tester, _pestanaFavoritos);
    expect(find.text(_vacio), findsOneWidget);

    await tocar(tester, find.text('Ir a Fichas'));
    expect(find.text('Fichas de estudio'), findsOneWidget);
  });

  test('los favoritos siguen ahí tras cerrar y volver a abrir la caja', () async {
    await prepararHive();
    final antes = FavoritosRepository();
    await antes.abrirParaUsuario(7);
    antes.guardar(
      FichaResumen.fromJson(
        ServidorFalso.ficha(3, 'SD2-S01', 'sistemas_digitales_2', 'Sistemas Digitales II', 'Introducción a VHDL', [
          'IEEE 1076',
        ]),
      ),
    );
    // Simula el cierre completo de la app.
    await Hive.close();

    final despues = FavoritosRepository();
    await despues.abrirParaUsuario(7);
    final lista = despues.listar();
    expect(lista, hasLength(1));
    expect(lista.single.codigo, 'SD2-S01');
    expect(lista.single.titulo, 'Introducción a VHDL');
    expect(lista.single.materia, 'sistemas_digitales_2');
    expect(lista.single.unidad, 1);
    expect(lista.single.normas, ['IEEE 1076']);
  });

  testWidgets('sin conexión después de una carga exitosa, la lista sale de la caché con aviso', (tester) async {
    await abrirApp(tester, servidor, token: _token);
    expect(find.textContaining('Sin conexión'), findsNothing);

    servidor.sinConexion = true;
    await tester.fling(find.text('Ancho de pistas en PCB'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(find.text('Ancho de pistas en PCB'), findsOneWidget);
    expect(find.textContaining('Sin conexión — fichas guardadas (última sincronización: '), findsOneWidget);

    // Con red de nuevo, Reintentar quita el aviso.
    servidor.sinConexion = false;
    await tocar(tester, find.text('Reintentar'));
    expect(find.textContaining('Sin conexión'), findsNothing);
    expect(find.text('Ancho de pistas en PCB'), findsOneWidget);
  });

  testWidgets('un 401 no usa la caché: cierra la sesión', (tester) async {
    await abrirApp(tester, servidor, token: _token);

    servidor
      ..codigoErrorFichas = 401
      ..fallasFichas = 1;
    await tester.fling(find.text('Ancho de pistas en PCB'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(find.textContaining('fichas guardadas'), findsNothing);
    expect(find.text('Tu sesión caducó. Inicia sesión de nuevo.'), findsOneWidget);
  });
}
