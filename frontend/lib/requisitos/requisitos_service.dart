import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class RequisitosService {
  RequisitosService({required this.baseUrl, http.Client? client})
      : client = client ?? http.Client();

  final String baseUrl;
  final http.Client client;

  Future<List<Requisito>> obtenerRequisitos(String estudianteId) async {
    final uri = Uri.parse('$baseUrl/requisitos/$estudianteId');
    final response = await client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('No se pudo cargar los requisitos');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => Requisito.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
