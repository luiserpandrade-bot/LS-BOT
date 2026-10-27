/// Persona con sesión iniciada (GET /usuarios/me).
class Usuario {
  const Usuario({required this.id, required this.email, required this.nombre});

  final int id;
  final String email;
  final String nombre;

  factory Usuario.fromJson(Map<String, dynamic> json) =>
      Usuario(id: json['id'] as int, email: json['email'] as String, nombre: json['nombre'] as String? ?? '');
}
