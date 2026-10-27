import 'package:flutter/material.dart';

import 'favoritos_screen.dart';
import 'fichas_screen.dart';
import 'perfil_screen.dart';
import 'proximamente_screen.dart';

/// Pantalla principal con la barra de navegación de cuatro pestañas.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _indice = 0;

  void _irAFichas() => setState(() => _indice = 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack conserva la lista (filtros y desplazamiento) al cambiar de pestaña.
      body: IndexedStack(
        index: _indice,
        children: [
          const FichasScreen(),
          ProximamenteScreen(
            titulo: 'LS-bot',
            icono: Icons.smart_toy_outlined,
            descripcion: 'Aquí podrás preguntarle al asistente LS-bot, que responde con el contenido de las fichas.',
            onIrAFichas: _irAFichas,
          ),
          FavoritosScreen(onIrAFichas: _irAFichas),
          const PerfilScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) => setState(() => _indice = i),
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
    );
  }
}
