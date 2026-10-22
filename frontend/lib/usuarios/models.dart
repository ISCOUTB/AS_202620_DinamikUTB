enum Rol {
  estudiante('Estudiante'),
  coordinador('Coordinador'),
  administrador('Administrador');

  const Rol(this.etiqueta);

  final String etiqueta;

  /// Asigna el rol de menor privilegio si el valor no se reconoce.
  static Rol desde(String valor) => Rol.values.firstWhere(
        (r) => r.name == valor,
        orElse: () => Rol.estudiante,
      );

  bool get esGestion => this != Rol.estudiante;
}

class Usuario {
  const Usuario({
    required this.id,
    required this.email,
    required this.rol,
    this.codigoEstudiantil,
  });

  final int id;
  final String email;
  final Rol rol;
  final String? codigoEstudiantil;

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as int,
      email: json['email'] as String,
      rol: Rol.desde(json['rol'] as String),
      codigoEstudiantil: json['codigo_estudiantil'] as String?,
    );
  }
}
