import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controllers/auth_controller.dart';
import 'controllers/dudas_controller.dart';
import 'controllers/fichas_controller.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/dudas_service.dart';
import 'services/fichas_service.dart';
import 'services/token_storage.dart';
import 'theme/app_theme.dart';
import 'widgets/cargando_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registrarDependencias();
  runApp(const LsBotApp());
}

/// Una sola instancia de cada servicio para toda la app. Las pruebas pasan
/// un `ApiClient` con un servidor falso y un `TokenStorage` en memoria.
void registrarDependencias({ApiClient? api, TokenStorage? almacen}) {
  final cliente = Get.put(api ?? ApiClient(), permanent: true);
  Get.put(almacen ?? TokenStorage(), permanent: true);
  Get.put(AuthService(cliente), permanent: true);
  Get.put(FichasService(cliente), permanent: true);
  Get.put(DudasService(cliente), permanent: true);
  // Se crean al abrir la lista o el detalle y se descartan al cerrar sesión;
  // `fenix` los vuelve a crear en la siguiente sesión.
  Get.lazyPut(() => FichasController(), fenix: true);
  Get.lazyPut(() => DudasController(), fenix: true);
  // Al crearse comprueba si hay un token guardado (restaurarSesion).
  Get.put(AuthController(), permanent: true);
}

class LsBotApp extends StatelessWidget {
  const LsBotApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return GetMaterialApp(
      title: 'LS-bot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.tema,
      home: Obx(() {
        if (auth.restaurando.value) {
          return const Scaffold(body: CargandoView(mensaje: 'Abriendo LS-bot...'));
        }
        return auth.estaAutenticado ? const HomeScreen() : const LoginScreen();
      }),
    );
  }
}
