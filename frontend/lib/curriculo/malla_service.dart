import 'package:frontend/core/network/api_client.dart';
import 'models.dart';

class MallaService {
  MallaService(this._api);

  final ApiClient _api;

  Future<MallaCurricular> obtener(String programa) async {
    final query = Uri(queryParameters: {'programa': programa}).query;
    final data = await _api.get('/malla?$query') as Map<String, dynamic>;
    return MallaCurricular.fromJson(data);
  }
}
