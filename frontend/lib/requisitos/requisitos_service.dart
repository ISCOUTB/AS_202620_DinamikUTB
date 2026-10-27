import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/network/api_exception.dart';
import 'models.dart';

class RequisitosService {
  RequisitosService(
    this._api, {
    this.maxIntentos = 3,
    this.esperaBase = const Duration(seconds: 2),
  }) : assert(maxIntentos > 0);

  final ApiClient _api;
  final int maxIntentos;
  final Duration esperaBase;

  String _base(String estudianteId) =>
      '/requisitos/${Uri.encodeComponent(estudianteId)}';

  Future<List<Requisito>> obtenerRequisitos(String estudianteId) async {
    ApiException? ultimoError;

    for (var intento = 1; intento <= maxIntentos; intento++) {
      try {
        final data = await _api.get(_base(estudianteId)) as List<dynamic>;
        return data
            .map((item) => Requisito.fromJson(item as Map<String, dynamic>))
            .toList();
      } on ApiException catch (error) {
        if ((error.statusCode != null && error.statusCode! < 500) ||
            intento == maxIntentos) {
          rethrow;
        }
        ultimoError = error;
        await Future<void>.delayed(esperaBase * (1 << (intento - 1)));
      }
    }

    if (ultimoError != null) throw ultimoError;
    throw StateError('La consulta de requisitos terminó sin respuesta.');
  }

  Future<ResumenRequisitos> obtenerResumen(String estudianteId) async {
    final data =
        await _api.get('${_base(estudianteId)}/resumen') as Map<String, dynamic>;
    return ResumenRequisitos.fromJson(data);
  }

  Future<Requisito> actualizarEstado(
    int requisitoId,
    EstadoRequisito estado,
  ) async {
    final data = await _api.put(
      '/requisitos/$requisitoId/estado',
      body: {'estado': estado.valorApi},
    ) as Map<String, dynamic>;
    return Requisito.fromJson(data);
  }
}
