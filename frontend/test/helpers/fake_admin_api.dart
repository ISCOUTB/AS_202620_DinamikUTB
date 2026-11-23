
import 'dart:convert';

import 'package:http/http.dart' as http;

class FakeAdminApiClient extends http.BaseClient {
  FakeAdminApiClient(this.handler);

  final dynamic Function(http.Request request) handler;
  final List<http.Request> requests = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final original = request as http.Request;
    requests.add(original);

    final result = handler(original);
    final statusCode = result is FakeApiResponse
        ? result.statusCode
        : 200;
    final body = result is FakeApiResponse ? result.body : result;

    return http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode(body))),
      statusCode,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }
}

class FakeApiResponse {
  const FakeApiResponse(this.body, {this.statusCode = 200});

  final dynamic body;
  final int statusCode;
}
