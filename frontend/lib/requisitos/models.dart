class Requisito {
  Requisito({required this.id, required this.nombre, required this.estado});

  final int id;
  final String nombre;
  final String estado;

  factory Requisito.fromJson(Map<String, dynamic> json) {
    return Requisito(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      estado: json['estado'] as String,
    );
  }
}
