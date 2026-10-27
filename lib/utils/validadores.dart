/// Reglas de los formularios, las mismas que aplica el backend
/// (`backend/app/schemas.py`). Validar aquí evita un viaje inútil al
/// servidor; el servidor sigue siendo quien decide.
class Validadores {
  Validadores._();

  static final _correo = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? correo(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Escribe tu correo';
    return _correo.hasMatch(texto) ? null : 'Escribe un correo válido';
  }

  /// De 2 a 80 caracteres.
  static String? nombre(String? valor) {
    final largo = valor?.trim().length ?? 0;
    return (largo >= 2 && largo <= 80) ? null : 'El nombre debe tener entre 2 y 80 caracteres';
  }

  /// De 8 a 72 caracteres.
  static String? password(String? valor) {
    final largo = valor?.length ?? 0;
    return (largo >= 8 && largo <= 72) ? null : 'La contraseña debe tener entre 8 y 72 caracteres';
  }
}
