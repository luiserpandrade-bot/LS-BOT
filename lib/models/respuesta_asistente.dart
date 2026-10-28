/// Ficha que LS-bot usó para responder (para abrir su detalle).
class FuenteAsistente {
  const FuenteAsistente({required this.id, required this.codigo, required this.titulo});

  final int id;
  final String codigo;
  final String titulo;

  factory FuenteAsistente.fromJson(Map<String, dynamic> json) =>
      FuenteAsistente(id: json['id'] as int, codigo: json['codigo'] as String, titulo: json['titulo'] as String);

  Map<String, dynamic> toJson() => {'id': id, 'codigo': codigo, 'titulo': titulo};
}

/// Respuesta de POST /asistente/. `modo` es "gemini" o "reglas" (sin clave
/// de IA en el backend).
class RespuestaAsistente {
  const RespuestaAsistente({required this.respuesta, required this.modo, required this.fuentes});

  final String respuesta;
  final String modo;
  final List<FuenteAsistente> fuentes;

  factory RespuestaAsistente.fromJson(Map<String, dynamic> json) => RespuestaAsistente(
    respuesta: json['respuesta'] as String,
    modo: json['modo'] as String,
    fuentes: fuentesDesde(json['fuentes']),
  );
}

/// Convierte una lista JSON (o null) en fuentes.
List<FuenteAsistente> fuentesDesde(Object? valor) => valor is List
    ? valor.map((e) => FuenteAsistente.fromJson(Map<String, dynamic>.from(e as Map))).toList()
    : const <FuenteAsistente>[];
