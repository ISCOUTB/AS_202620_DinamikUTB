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
    this.nombre,
    this.programa,
    this.semestre,
  });

  final int id;
  final String email;
  final Rol rol;
  final String? codigoEstudiantil;
  final String? nombre;
  final String? programa;
  final int? semestre;

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as int,
      email: json['email'] as String,
      rol: Rol.desde(json['rol'] as String),
      codigoEstudiantil: json['codigo_estudiantil'] as String?,
      nombre: json['nombre'] as String?,
      programa: json['programa'] as String?,
      semestre: json['semestre'] as int?,
    );
  }
}
