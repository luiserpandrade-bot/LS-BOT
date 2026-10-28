import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'controllers/asistente_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/dudas_controller.dart';
import 'controllers/favoritos_controller.dart';
import 'controllers/fichas_controller.dart';
import 'controllers/navegacion_controller.dart';
import 'repositories/chat_repository.dart';
import 'repositories/favoritos_repository.dart';
import 'repositories/fichas_repository.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_client.dart';
import 'services/asistente_service.dart';
import 'services/auth_service.dart';
import 'services/dudas_service.dart';
import 'services/fichas_service.dart';
import 'services/token_storage.dart';
import 'theme/app_theme.dart';
import 'widgets/cargando_view.dart';

Future<void> main() async {
  // Hive necesita el motor listo para pedir la carpeta de la app.
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  // La caché de fichas es común; las cajas de favoritos y de chat dependen
  // de quién entre y las abre `AuthController`.
  await FichasRepository.abrirCaja();
  registrarDependencias();
  runApp(const LsBotApp());
}

/// Una sola instancia de cada servicio para toda la app. Las pruebas pasan
/// un `ApiClient` con un servidor falso y un `TokenStorage` en memoria.
void registrarDependencias({ApiClient? api, TokenStorage? almacen}) {
  final cliente = Get.put(api ?? ApiClient(), permanent: true);
  Get.put(almacen ?? TokenStorage(), permanent: true);
  Get.put(AuthService(cliente), permanent: true);
  final fichas = Get.put(FichasService(cliente), permanent: true);
  Get.put(DudasService(cliente), permanent: true);
  Get.put(FichasRepository(fichas), permanent: true);
  Get.put(FavoritosRepository(), permanent: true);
  Get.put(AsistenteService(cliente), permanent: true);
  Get.put(ChatRepository(), permanent: true);
  // Viven toda la app: al cerrar sesión se vacían (el chat, también del disco).
  Get.put(FavoritosController(), permanent: true);
  Get.put(AsistenteController(), permanent: true);
  Get.put(NavegacionController(), permanent: true);
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
