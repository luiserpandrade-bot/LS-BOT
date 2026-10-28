import 'package:get/get.dart';

/// Pestaña visible de Home. Vive aquí para que otras pantallas (por ejemplo,
/// el detalle de una ficha) puedan llevar a LS-bot.
class NavegacionController extends GetxController {
  static const fichas = 0;
  static const lsBot = 1;

  final RxInt pestana = fichas.obs;

  void irA(int indice) => pestana.value = indice;
}
