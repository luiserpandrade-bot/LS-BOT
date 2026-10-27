/// Duda publicada en una ficha (GET /fichas/{id}/dudas). La ven todos; solo
/// su autor (`esMia`) puede editarla o borrarla.
class Duda {
  const Duda({
    required this.id,
    required this.fichaId,
    required this.texto,
    required this.autor,
    required this.esMia,
    required this.creado,
    this.editado,
  });

  final int id;
  final int fichaId;
  final String texto;
  final String autor;
  final bool esMia;
  final DateTime creado;
  final DateTime? editado;

  bool get fueEditada => editado != null;

  factory Duda.fromJson(Map<String, dynamic> json) => Duda(
    id: json['id'] as int,
    fichaId: json['ficha_id'] as int,
    texto: json['texto'] as String,
    autor: json['autor'] as String,
    esMia: json['es_mia'] as bool? ?? false,
    creado: DateTime.parse(json['creado'] as String).toLocal(),
    editado: json['editado'] == null ? null : DateTime.parse(json['editado'] as String).toLocal(),
  );
}
