/// Ficha de estudio tal como llega en la lista (GET /fichas/).
class FichaResumen {
  const FichaResumen({
    required this.id,
    required this.codigo,
    required this.materia,
    required this.materiaNombre,
    required this.unidad,
    required this.unidadNombre,
    required this.sesion,
    required this.titulo,
    required this.normas,
  });

  final int id;
  final String codigo;
  final String materia;
  final String materiaNombre;
  final int unidad;
  final String unidadNombre;
  final String sesion;
  final String titulo;
  final List<String> normas;

  factory FichaResumen.fromJson(Map<String, dynamic> json) => FichaResumen(
    id: json['id'] as int,
    codigo: json['codigo'] as String,
    materia: json['materia'] as String,
    materiaNombre: json['materia_nombre'] as String,
    unidad: json['unidad'] as int,
    unidadNombre: json['unidad_nombre'] as String,
    sesion: json['sesion'] as String? ?? '',
    titulo: json['titulo'] as String,
    normas: listaDeTextos(json['normas']),
  );
}

/// Convierte una lista JSON (o null) en `List<String>`.
List<String> listaDeTextos(Object? valor) => valor is List ? valor.map((e) => '$e').toList() : const <String>[];
