import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/favoritos_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/ficha_card.dart';
import '../widgets/vacio_view.dart';
import 'ficha_detalle_screen.dart';

/// Fichas guardadas como favoritas; se leen de Hive, también sin conexión.
class FavoritosScreen extends StatelessWidget {
  const FavoritosScreen({super.key, required this.onIrAFichas});

  final VoidCallback onIrAFichas;

  @override
  Widget build(BuildContext context) {
    final favoritos = Get.find<FavoritosController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: Obx(() {
        final lista = favoritos.favoritos.toList();
        if (lista.isEmpty) {
          return VacioView(
            icono: Icons.bookmark_border,
            titulo: 'Aún no tienes fichas favoritas',
            mensaje: 'Toca el marcador de una ficha para guardarla aquí.',
            textoAccion: 'Ir a Fichas',
            onAccion: onIrAFichas,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: lista.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, i) {
            final ficha = lista[i];
            return FichaCard(
              ficha: ficha,
              favorito: true,
              onFavorito: () => favoritos.alternar(ficha),
              onTap: () => Get.to(() => FichaDetalleScreen(id: ficha.id, codigo: ficha.codigo)),
            );
          },
        );
      }),
    );
  }
}
