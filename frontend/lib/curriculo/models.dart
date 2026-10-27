class CursoCurricular {
  const CursoCurricular({
    required this.codigo,
    required this.nombre,
    required this.nivel,
    required this.creditos,
    required this.prerequisitos,
  });

  final String codigo;
  final String nombre;
  final int nivel;
  final int creditos;
  final List<String> prerequisitos;

  factory CursoCurricular.fromJson(Map<String, dynamic> json) =>
      CursoCurricular(
        codigo: json['codigo'] as String,
        nombre: json['nombre'] as String,
        nivel: json['nivel'] as int,
        creditos: json['creditos'] as int,
        prerequisitos: (json['prerequisitos'] as List<dynamic>).cast<String>(),
      );
}

class MallaCurricular {
  const MallaCurricular({
    required this.programa,
    required this.plan,
    required this.creditosTotales,
    required this.cursos,
  });

  final String programa;
  final String plan;
  final int creditosTotales;
  final List<CursoCurricular> cursos;

  int get niveles => cursos.map((curso) => curso.nivel).toSet().length;

  int get creditosCatalogo =>
      cursos.fold(0, (total, curso) => total + curso.creditos);

  factory MallaCurricular.fromJson(Map<String, dynamic> json) =>
      MallaCurricular(
        programa: json['programa'] as String,
        plan: json['plan'] as String,
        creditosTotales: json['creditos_totales'] as int,
        cursos: (json['cursos'] as List<dynamic>)
            .map(
              (curso) =>
                  CursoCurricular.fromJson(curso as Map<String, dynamic>),
            )
            .toList(),
      );
}
