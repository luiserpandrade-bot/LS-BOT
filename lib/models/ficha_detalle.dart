import 'ficha_resumen.dart';

/// Ficha completa (GET /fichas/{id}).
class FichaDetalle extends FichaResumen {
  const FichaDetalle({
    required super.id,
    required super.codigo,
    required super.materia,
    required super.materiaNombre,
    required super.unidad,
    required super.unidadNombre,
    required super.sesion,
    required super.titulo,
    required super.normas,
    required this.silabo,
    required this.ideasClave,
    required this.formulas,
    required this.preguntas,
    required this.fuente,
    required this.totalDudas,
  });

  final String silabo;
  final List<String> ideasClave;
  final List<String> formulas;
  final List<String> preguntas;
  final String fuente;
  final int totalDudas;

  factory FichaDetalle.fromJson(Map<String, dynamic> json) {
    final r = FichaResumen.fromJson(json);
    return FichaDetalle(
      id: r.id,
      codigo: r.codigo,
      materia: r.materia,
      materiaNombre: r.materiaNombre,
      unidad: r.unidad,
      unidadNombre: r.unidadNombre,
      sesion: r.sesion,
      titulo: r.titulo,
      normas: r.normas,
      silabo: json['silabo'] as String? ?? '',
      ideasClave: listaDeTextos(json['ideas_clave']),
      formulas: listaDeTextos(json['formulas']),
      preguntas: listaDeTextos(json['preguntas']),
      fuente: json['fuente'] as String? ?? '',
      totalDudas: json['total_dudas'] as int? ?? 0,
    );
  }
}
