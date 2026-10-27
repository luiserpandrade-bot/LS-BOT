/// Materia con fichas (GET /fichas/materias).
class Materia {
  const Materia({required this.codigo, required this.nombre, this.totalFichas = 0});

  /// Valor que se envía en `?materia=`, por ejemplo `sistemas_digitales_1`.
  final String codigo;
  final String nombre;
  final int totalFichas;

  factory Materia.fromJson(Map<String, dynamic> json) => Materia(
    codigo: json['materia'] as String,
    nombre: json['materia_nombre'] as String,
    totalFichas: json['total_fichas'] as int? ?? 0,
  );

  /// Las tres materias de LS-bot, para mostrar los filtros aunque
  /// /fichas/materias aún no haya respondido.
  static const conocidas = [
    Materia(codigo: 'diseno_electronico', nombre: 'Diseño Electrónico'),
    Materia(codigo: 'sistemas_digitales_1', nombre: 'Sistemas Digitales I'),
    Materia(codigo: 'sistemas_digitales_2', nombre: 'Sistemas Digitales II'),
  ];
}
