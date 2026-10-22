import '../core/network/api_client.dart';
import 'models.dart';

class EstudiantesService {
  EstudiantesService(this._api);

  final ApiClient _api;

  Future<Estudiante> obtener(String codigoEstudiantil) async {
    // Codifica el código estudiantil como un único segmento de ruta.
    final data = await _api
        .get('/estudiantes/${Uri.encodeComponent(codigoEstudiantil)}') as Map<String, dynamic>;
    return Estudiante.fromJson(data);
  }
}
