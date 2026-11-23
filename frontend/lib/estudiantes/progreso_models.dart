DateTime? _fecha(Object? v) => v is String ? DateTime.tryParse(v) : null;

List<String> _lista(Object? v) =>
    ((v as List<dynamic>?) ?? const <dynamic>[]).cast<String>();

class CursoProgreso {
  const CursoProgreso({
    required this.codigo,
    required this.nombre,
    required this.nivel,
    required this.creditos,
    required this.prerequisitos,
    required this.desbloquea,
    required this.estado,
    required this.desbloqueada,
    required this.prerequisitosFaltantes,
    this.fechaAprobacion,
    this.periodo,
    this.nota,
  });

  final String codigo;
  final String nombre;
  final int nivel;
  final int creditos;
  final List<String> prerequisitos;
  final List<String> desbloquea;
  final String estado;
  final bool desbloqueada;
  final List<String> prerequisitosFaltantes;
  final DateTime? fechaAprobacion;
  final String? periodo;
  final double? nota;

  bool get aprobado => estado == 'aprobado';
  bool get enCurso => estado == 'en_curso';
  bool get pendiente => estado == 'pendiente';

  factory CursoProgreso.fromJson(Map<String, dynamic> j) => CursoProgreso(
    codigo: j['codigo'] as String,
    nombre: j['nombre'] as String,
    nivel: j['nivel'] as int,
    creditos: j['creditos'] as int,
    prerequisitos: _lista(j['prerequisitos']),
    desbloquea: _lista(j['desbloquea']),
    estado: j['estado'] as String,
    desbloqueada: j['desbloqueada'] as bool,
    prerequisitosFaltantes: _lista(j['prerequisitos_faltantes']),
    fechaAprobacion: _fecha(j['fecha_aprobacion']),
    periodo: j['periodo'] as String?,
    nota: (j['nota'] as num?)?.toDouble(),
  );
}

class NivelProgreso {
  const NivelProgreso({
    required this.nivel,
    required this.creditosTotales,
    required this.creditosAprobados,
    required this.porcentaje,
  });

  final int nivel;
  final int creditosTotales;
  final int creditosAprobados;
  final double porcentaje;

  factory NivelProgreso.fromJson(Map<String, dynamic> j) => NivelProgreso(
    nivel: j['nivel'] as int,
    creditosTotales: j['creditos_totales'] as int,
    creditosAprobados: j['creditos_aprobados'] as int,
    porcentaje: (j['porcentaje'] as num).toDouble(),
  );
}

class ResumenProgreso {
  const ResumenProgreso({
    required this.creditosTotales,
    required this.creditosAprobados,
    required this.creditosEnCurso,
    required this.creditosPendientes,
    required this.porcentajeGlobal,
    required this.cursosAprobados,
    required this.cursosTotal,
    required this.semestresRestantes,
    this.promedioAcumulado,
    this.periodoGradoEstimado,
  });

  final int creditosTotales;
  final int creditosAprobados;
  final int creditosEnCurso;
  final int creditosPendientes;
  final double porcentajeGlobal;
  final double? promedioAcumulado;
  final int cursosAprobados;
  final int cursosTotal;
  final int semestresRestantes;
  final String? periodoGradoEstimado;

  factory ResumenProgreso.fromJson(Map<String, dynamic> j) => ResumenProgreso(
    creditosTotales: j['creditos_totales'] as int,
    creditosAprobados: j['creditos_aprobados'] as int,
    creditosEnCurso: j['creditos_en_curso'] as int,
    creditosPendientes: j['creditos_pendientes'] as int,
    porcentajeGlobal: (j['porcentaje_global'] as num).toDouble(),
    promedioAcumulado: (j['promedio_acumulado'] as num?)?.toDouble(),
    cursosAprobados: j['cursos_aprobados'] as int,
    cursosTotal: j['cursos_total'] as int,
    semestresRestantes: j['semestres_restantes'] as int,
    periodoGradoEstimado: j['periodo_grado_estimado'] as String?,
  );
}

class ProgresoMalla {
  const ProgresoMalla({
    required this.codigoEstudiantil,
    required this.programa,
    required this.plan,
    required this.periodoActual,
    required this.resumen,
    required this.niveles,
    required this.cursos,
  });

  final String codigoEstudiantil;
  final String programa;
  final String plan;
  final String periodoActual;
  final ResumenProgreso resumen;
  final List<NivelProgreso> niveles;
  final List<CursoProgreso> cursos;

  factory ProgresoMalla.fromJson(Map<String, dynamic> j) => ProgresoMalla(
    codigoEstudiantil: j['codigo_estudiantil'] as String,
    programa: j['programa'] as String,
    plan: j['plan'] as String,
    periodoActual: j['periodo_actual'] as String,
    resumen: ResumenProgreso.fromJson(j['resumen'] as Map<String, dynamic>),
    niveles: (j['niveles'] as List<dynamic>)
        .map((e) => NivelProgreso.fromJson(e as Map<String, dynamic>))
        .toList(),
    cursos: (j['cursos'] as List<dynamic>)
        .map((e) => CursoProgreso.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class PasoGuia {
  const PasoGuia({required this.titulo, this.detalle = '', this.oficina = ''});

  final String titulo;
  final String detalle;
  final String oficina;

  factory PasoGuia.fromJson(Map<String, dynamic> j) => PasoGuia(
    titulo: j['titulo'] as String,
    detalle: (j['detalle'] as String?) ?? '',
    oficina: (j['oficina'] as String?) ?? '',
  );
}

class RutaRequisito {
  const RutaRequisito({
    required this.id,
    required this.nombre,
    required this.estado,
    this.codigoInterno,
    this.categoria,
    this.fechaCumplimiento,
    this.periodo,
    this.evidencia,
    this.porcentajeCreditosRequerido,
    this.creditosRequeridos,
    this.creditosFaltantes,
    this.habilitado,
    this.portalOficial,
    this.tiempoEstimado,
    this.guiaResumen,
    this.pasosGuia = const [],
  });

  final int id;
  final String nombre;
  final String estado;
  final String? codigoInterno;
  final String? categoria;
  final DateTime? fechaCumplimiento;
  final String? periodo;
  final String? evidencia;
  final int? porcentajeCreditosRequerido;
  final int? creditosRequeridos;
  final int? creditosFaltantes;
  final bool? habilitado;
  final String? portalOficial;
  final String? tiempoEstimado;
  final String? guiaResumen;
  final List<PasoGuia> pasosGuia;

  factory RutaRequisito.fromJson(Map<String, dynamic> j) => RutaRequisito(
    id: j['id'] as int,
    nombre: j['nombre'] as String,
    estado: j['estado'] as String,
    codigoInterno: j['codigo_interno'] as String?,
    categoria: j['categoria'] as String?,
    fechaCumplimiento: _fecha(j['fecha_cumplimiento']),
    periodo: j['periodo'] as String?,
    evidencia: j['evidencia'] as String?,
    porcentajeCreditosRequerido: j['porcentaje_creditos_requerido'] as int?,
    creditosRequeridos: j['creditos_requeridos'] as int?,
    creditosFaltantes: j['creditos_faltantes'] as int?,
    habilitado: j['habilitado'] as bool?,
    portalOficial: j['portal_oficial'] as String?,
    tiempoEstimado: j['tiempo_estimado'] as String?,
    guiaResumen: j['guia_resumen'] as String?,
    pasosGuia: ((j['pasos_guia'] as List<dynamic>?) ?? const <dynamic>[])
        .map((e) => PasoGuia.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
