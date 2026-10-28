import 'respuesta_asistente.dart';

enum RolMensaje { usuario, bot }

/// Un mensaje del chat con LS-bot, tal como se guarda en Hive. `modo` y
/// `fuentes` solo tienen valor en las respuestas del bot.
class MensajeChat {
  const MensajeChat({
    required this.rol,
    required this.texto,
    required this.fecha,
    this.modo,
    this.fuentes = const [],
  });

  final RolMensaje rol;
  final String texto;
  final DateTime fecha;
  final String? modo;
  final List<FuenteAsistente> fuentes;

  bool get esDelBot => rol == RolMensaje.bot;
  bool get esModoReglas => modo == 'reglas';

  factory MensajeChat.fromJson(Map<String, dynamic> json) => MensajeChat(
    rol: json['rol'] == 'bot' ? RolMensaje.bot : RolMensaje.usuario,
    texto: json['texto'] as String,
    fecha: DateTime.parse(json['fecha'] as String),
    modo: json['modo'] as String?,
    fuentes: fuentesDesde(json['fuentes']),
  );

  Map<String, dynamic> toJson() => {
    'rol': rol.name,
    'texto': texto,
    'fecha': fecha.toIso8601String(),
    'modo': modo,
    'fuentes': fuentes.map((f) => f.toJson()).toList(),
  };
}
