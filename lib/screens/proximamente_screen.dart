import 'package:flutter/material.dart';

import '../widgets/vacio_view.dart';

/// Pestaña aún no disponible: explica qué habrá y lleva a Fichas para no
/// dejar un callejón sin salida.
class ProximamenteScreen extends StatelessWidget {
  const ProximamenteScreen({
    super.key,
    required this.titulo,
    required this.icono,
    required this.descripcion,
    required this.onIrAFichas,
  });

  final String titulo;
  final IconData icono;
  final String descripcion;
  final VoidCallback onIrAFichas;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: VacioView(
        icono: icono,
        titulo: 'Disponible en la siguiente versión',
        mensaje: descripcion,
        textoAccion: 'Ir a Fichas',
        onAccion: onIrAFichas,
      ),
    );
  }
}
