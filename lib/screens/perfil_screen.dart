import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../theme/app_theme.dart';

/// Datos de la persona con sesión iniciada y cierre de sesión.
class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Obx(() {
            final usuario = auth.usuario.value;
            return Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Nombre'),
                    subtitle: Text(usuario?.nombre ?? '', style: tema.textTheme.bodyLarge),
                  ),
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: const Text('Correo'),
                    subtitle: Text(usuario?.email ?? '', style: tema.textTheme.bodyLarge),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton.icon(
            onPressed: auth.cerrarSesion,
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
          ),
        ],
      ),
    );
  }
}
