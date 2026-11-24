
import 'package:frontend/core/network/api_client.dart';
import 'progreso_models.dart';

/// Lee el avance curricular y la ruta de requisitos del estudiante.
class ProgresoService {
  ProgresoService(this._api);

  final ApiClient _api;

  Future<ProgresoMalla> obtenerProgreso(String codigo) async {
    final data =
        await _api.get('/malla/progreso/${Uri.encodeComponent(codigo)}')
            as Map<String, dynamic>;
    return ProgresoMalla.fromJson(data);
  }

  Future<List<RutaRequisito>> obtenerRuta(String codigo) async {
    final data =
        await _api.get('/requisitos/${Uri.encodeComponent(codigo)}/ruta')
            as List<dynamic>;
    return data
        .map((e) => RutaRequisito.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
