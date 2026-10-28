import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/navegacion_controller.dart';
import 'asistente_screen.dart';
import 'favoritos_screen.dart';
import 'fichas_screen.dart';
import 'perfil_screen.dart';

/// Pantalla principal con la barra de navegación de cuatro pestañas. La
/// pestaña visible vive en `NavegacionController`.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final navegacion = Get.find<NavegacionController>();
    void irAFichas() => navegacion.irA(NavegacionController.fichas);
    return Obx(
      () => Scaffold(
        // IndexedStack conserva la lista (filtros y desplazamiento) al cambiar de pestaña.
        body: IndexedStack(
          index: navegacion.pestana.value,
          children: [
            const FichasScreen(),
            const AsistenteScreen(),
            FavoritosScreen(onIrAFichas: irAFichas),
            const PerfilScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: navegacion.pestana.value,
          onDestinationSelected: navegacion.irA,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: 'Fichas',
            ),
            NavigationDestination(
              icon: Icon(Icons.smart_toy_outlined),
              selectedIcon: Icon(Icons.smart_toy),
              label: 'LS-bot',
            ),
            NavigationDestination(
              icon: Icon(Icons.bookmark_border),
              selectedIcon: Icon(Icons.bookmark),
              label: 'Favoritos',
            ),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
          ],
        ),
      ),
    );
  }
}
