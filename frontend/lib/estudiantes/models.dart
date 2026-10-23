class Estudiante {
  const Estudiante({
    required this.id,
    required this.codigoEstudiantil,
    required this.nombre,
    required this.programa,
  });

  final int id;
  final String codigoEstudiantil;
  final String nombre;
  final String programa;

  factory Estudiante.fromJson(Map<String, dynamic> json) {
    return Estudiante(
      id: json['id'] as int,
      codigoEstudiantil: json['codigo_estudiantil'] as String,
      nombre: json['nombre'] as String,
      programa: json['programa'] as String,
    );
  }
}
