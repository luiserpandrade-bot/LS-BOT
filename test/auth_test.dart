import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'apoyo/servidor_falso.dart';

void main() {
  late ServidorFalso servidor;

  setUp(() {
    reiniciarGetX();
    servidor = ServidorFalso();
  });
  tearDown(reiniciarGetX);

  testWidgets('login con contraseña incorrecta muestra el mensaje del servidor', (tester) async {
    await abrirApp(tester, servidor);
    expect(find.text('Iniciar sesión'), findsOneWidget);

    await tester.enterText(campo('Correo'), 'ana@ups.edu.ec');
    await tester.enterText(campo('Contraseña'), 'otra-clave-1');
    await tocar(tester, find.widgetWithText(FilledButton, 'Iniciar sesión'));

    expect(find.text('Email o contraseña incorrectos'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    // El login va como formulario, no como JSON.
    final login = servidor.peticiones.singleWhere((o) => o.path == '/usuarios/token');
    expect(login.contentType, contains('application/x-www-form-urlencoded'));
  });

  testWidgets('login correcto abre la pantalla principal y el perfil muestra los datos', (tester) async {
    await abrirApp(tester, servidor);

    await tester.enterText(campo('Correo'), 'ana@ups.edu.ec');
    await tester.enterText(campo('Contraseña'), 'clave12345');
    await tocar(tester, find.widgetWithText(FilledButton, 'Iniciar sesión'));

    expect(find.byType(NavigationBar), findsOneWidget);
    await tocar(tester, find.text('Perfil'));
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('ana@ups.edu.ec'), findsOneWidget);

    await tocar(tester, find.text('Cerrar sesión'));
    expect(find.widgetWithText(FilledButton, 'Iniciar sesión'), findsOneWidget);
  });

  testWidgets('la validación local evita enviar un correo o contraseña inválidos', (tester) async {
    await abrirApp(tester, servidor);

    await tester.enterText(campo('Correo'), 'ana-sin-arroba');
    await tester.enterText(campo('Contraseña'), 'corta');
    await tocar(tester, find.widgetWithText(FilledButton, 'Iniciar sesión'));

    expect(find.text('Escribe un correo válido'), findsOneWidget);
    expect(find.text('La contraseña debe tener entre 8 y 72 caracteres'), findsOneWidget);
    expect(servidor.peticiones, isEmpty);
  });

  testWidgets('un token guardado que ya no sirve lleva al login con aviso', (tester) async {
    await abrirApp(tester, servidor, token: 'tok-nadie@ups.edu.ec');

    expect(find.widgetWithText(FilledButton, 'Iniciar sesión'), findsOneWidget);
    expect(find.text('Tu sesión caducó. Inicia sesión de nuevo.'), findsOneWidget);
  });
}
