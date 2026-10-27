import 'dart:typed_data';

import 'package:frontend/core/network/api_client.dart';

class AdminService {
  AdminService(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> resumen() async =>
      await _api.get('/estudiantes/estadisticas/resumen')
          as Map<String, dynamic>;

  Future<Uint8List> exportarEstudiantes() =>
      _api.getBytes('/reportes/estudiantes.csv');

  Future<List<AdminStudent>> estudiantes({
    String? buscar,
    String? programa,
    int? semestre,
    bool? activo,
    int limite = 50,
    int offset = 0,
  }) async {
    final query = <String, String>{};
    if (buscar?.trim().isNotEmpty ?? false) query['buscar'] = buscar!.trim();
    if (programa != null) query['programa'] = programa;
    if (semestre != null) query['semestre'] = '$semestre';
    if (activo != null) query['activo'] = '$activo';
    query['limite'] = '$limite';
    query['desplazamiento'] = '$offset';
    final suffix = query.isEmpty ? '' : '?${Uri(queryParameters: query).query}';
    final data = await _api.get('/estudiantes$suffix') as List<dynamic>;
    return data
        .map((item) => AdminStudent.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AdminStudent> crearEstudiante(Map<String, Object> payload) async {
    final data =
        await _api.post('/estudiantes', body: payload) as Map<String, dynamic>;
    return AdminStudent.fromJson(data);
  }

  Future<AdminStudent> actualizarEstudiante(
    String codigo,
    Map<String, Object> payload,
  ) async {
    final data =
        await _api.put(
              '/estudiantes/${Uri.encodeComponent(codigo)}/administrativo',
              body: payload,
            )
            as Map<String, dynamic>;
    return AdminStudent.fromJson(data);
  }

  Future<List<AdminProgram>> programas({bool administrar = false}) async {
    final path = administrar ? '/programas/administracion' : '/programas';
    final data = await _api.get(path) as List<dynamic>;
    return data
        .map((item) => AdminProgram.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AdminProgram> crearPrograma(Map<String, Object> payload) async {
    final data =
        await _api.post('/programas', body: payload) as Map<String, dynamic>;
    return AdminProgram.fromJson(data);
  }

  Future<AdminProgram> actualizarPrograma(
    int id,
    Map<String, Object> payload,
  ) async {
    final data =
        await _api.put('/programas/$id', body: payload) as Map<String, dynamic>;
    return AdminProgram.fromJson(data);
  }

  Future<List<AdminRequirement>> requisitos({int? programaId}) async {
    final suffix = programaId == null ? '' : '?programa_id=$programaId';
    final data = await _api.get('/requisitos/catalogo$suffix') as List<dynamic>;
    return data
        .map((item) => AdminRequirement.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AdminRequirement> crearRequisito(Map<String, Object> payload) async {
    final data =
        await _api.post('/requisitos/catalogo', body: payload)
            as Map<String, dynamic>;
    return AdminRequirement.fromJson(data);
  }

  Future<AdminRequirement> actualizarRequisito(
    int id,
    Map<String, Object> payload,
  ) async {
    final data =
        await _api.put('/requisitos/catalogo/$id', body: payload)
            as Map<String, dynamic>;
    return AdminRequirement.fromJson(data);
  }

  Future<List<AdminAccount>> cuentasAdministrativas() async {
    final data = await _api.get('/auth/administradores') as List<dynamic>;
    return data
        .map((item) => AdminAccount.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AdminAccount> crearCuenta({
    required String email,
    required String password,
    required String rol,
  }) async {
    final data =
        await _api.post(
              '/auth/administradores?rol=${Uri.encodeQueryComponent(rol)}',
              body: {'email': email, 'password': password},
            )
            as Map<String, dynamic>;
    return AdminAccount.fromJson(data);
  }

  Future<AdminAccount> actualizarCuenta(
    int id, {
    required String rol,
    required bool activo,
  }) async {
    final data =
        await _api.put(
              '/auth/administradores/$id?activo=$activo&rol=${Uri.encodeQueryComponent(rol)}',
            )
            as Map<String, dynamic>;
    return AdminAccount.fromJson(data);
  }

  Future<String> emitirRecuperacion(int usuarioId) async {
    final data =
        await _api.post('/auth/administradores/$usuarioId/recuperacion')
            as Map<String, dynamic>;
    return data['reset_token'] as String;
  }
}

class AdminStudent {
  const AdminStudent({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.email,
    required this.programa,
    required this.semestre,
    required this.activo,
  });

  final int id;
  final String codigo;
  final String nombre;
  final String email;
  final String programa;
  final int? semestre;
  final bool activo;

  factory AdminStudent.fromJson(Map<String, dynamic> json) => AdminStudent(
    id: json['id'] as int,
    codigo: json['codigo_estudiantil'] as String,
    nombre: json['nombre'] as String,
    email: json['email'] as String,
    programa: json['programa'] as String,
    semestre: json['semestre'] as int?,
    activo: json['activo'] as bool,
  );
}

class AdminProgram {
  const AdminProgram({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.facultad,
    required this.duracionSemestres,
    required this.activo,
    required this.estudiantes,
  });

  final int id;
  final String codigo;
  final String nombre;
  final String facultad;
  final int duracionSemestres;
  final bool activo;
  final int estudiantes;

  factory AdminProgram.fromJson(Map<String, dynamic> json) => AdminProgram(
    id: json['id'] as int,
    codigo: json['codigo'] as String,
    nombre: json['nombre'] as String,
    facultad: json['facultad'] as String,
    duracionSemestres: json['duracion_semestres'] as int,
    activo: json['activo'] as bool,
    estudiantes: json['estudiantes_asociados'] as int? ?? 0,
  );
}

class AdminRequirement {
  const AdminRequirement({
    required this.id,
    required this.programaId,
    required this.programa,
    required this.nombre,
    required this.descripcion,
    required this.semestre,
    required this.obligatorio,
    required this.activo,
  });

  final int id;
  final int programaId;
  final String programa;
  final String nombre;
  final String descripcion;
  final int semestre;
  final bool obligatorio;
  final bool activo;

  factory AdminRequirement.fromJson(Map<String, dynamic> json) =>
      AdminRequirement(
        id: json['id'] as int,
        programaId: json['programa_id'] as int,
        programa: json['programa'] as String,
        nombre: json['nombre'] as String,
        descripcion: json['descripcion'] as String,
        semestre: json['semestre_recomendado'] as int,
        obligatorio: json['obligatorio'] as bool,
        activo: json['activo'] as bool,
      );
}

class AdminAccount {
  const AdminAccount({
    required this.id,
    required this.email,
    required this.rol,
    required this.activo,
    this.codigo,
  });

  final int id;
  final String email;
  final String rol;
  final bool activo;
  final String? codigo;

  factory AdminAccount.fromJson(Map<String, dynamic> json) => AdminAccount(
    id: json['id'] as int,
    email: json['email'] as String,
    rol: json['rol'] as String,
    activo: json['activo'] as bool,
    codigo: json['codigo_estudiantil'] as String?,
  );
}
