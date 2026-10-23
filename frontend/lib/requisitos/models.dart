enum EstadoRequisito {
  cumplido('cumplido', 'Cumplido'),
  enProceso('en_proceso', 'En proceso'),
  pendiente('pendiente', 'Pendiente');

  const EstadoRequisito(this.valorApi, this.etiqueta);

  final String valorApi;
  final String etiqueta;

  /// Usa pendiente como valor predeterminado para estados desconocidos.
  static EstadoRequisito desde(String valor) => EstadoRequisito.values.firstWhere(
        (e) => e.valorApi == valor,
        orElse: () => EstadoRequisito.pendiente,
      );
}

class Requisito {
  const Requisito({required this.id, required this.nombre, required this.estado});

  final int id;
  final String nombre;
  final EstadoRequisito estado;

  factory Requisito.fromJson(Map<String, dynamic> json) {
    return Requisito(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      estado: EstadoRequisito.desde(json['estado'] as String),
    );
  }
}

class ResumenRequisitos {
  const ResumenRequisitos({
    required this.total,
    required this.cumplidos,
    required this.enProceso,
    required this.pendientes,
    required this.porcentajeAvance,
  });

  final int total;
  final int cumplidos;
  final int enProceso;
  final int pendientes;
  final double porcentajeAvance;

  factory ResumenRequisitos.fromJson(Map<String, dynamic> json) {
    return ResumenRequisitos(
      total: json['total'] as int,
      cumplidos: json['cumplidos'] as int,
      enProceso: json['en_proceso'] as int,
      pendientes: json['pendientes'] as int,
      porcentajeAvance: (json['porcentaje_avance'] as num).toDouble(),
    );
  }
}
