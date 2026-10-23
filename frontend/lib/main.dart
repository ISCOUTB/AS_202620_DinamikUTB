import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'core/auth_gate.dart';
import 'core/config.dart';
import 'core/network/api_client.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/app_theme.dart';
import 'estudiantes/estudiantes_service.dart';
import 'requisitos/requisitos_service.dart';
import 'usuarios/auth_controller.dart';
import 'usuarios/auth_service.dart';

/// Construye las dependencias compartidas de la aplicación.
class AppDependencias {
  AppDependencias._(this.api, this.auth, this.estudiantes, this.requisitos);

  factory AppDependencias.crear({
    String baseUrl = apiBaseUrl,
    TokenStorage? storage,
    http.Client? client,
  }) {
    final almacen = storage ?? SecureTokenStorage();
    final api = ApiClient(baseUrl: baseUrl, tokenStorage: almacen, client: client);
    final auth = AuthController(service: AuthService(api), storage: almacen);
    api.onUnauthorized = () => auth.cerrarSesion(); // sesión vencida → vuelve al login
    return AppDependencias._(api, auth, EstudiantesService(api), RequisitosService(api));
  }

  final ApiClient api;
  final AuthController auth;
  final EstudiantesService estudiantes;
  final RequisitosService requisitos;
}

void main() {
  validarConfiguracion();
  runApp(DinamikApp(dependencias: AppDependencias.crear()));
}

class DinamikApp extends StatefulWidget {
  const DinamikApp({super.key, required this.dependencias});

  final AppDependencias dependencias;

  @override
  State<DinamikApp> createState() => _DinamikAppState();
}

class _DinamikAppState extends State<DinamikApp> {
  @override
  void initState() {
    super.initState();
    widget.dependencias.auth.restaurarSesion();
  }

  @override
  Widget build(BuildContext context) {
    final deps = widget.dependencias;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(value: deps.auth),
        Provider<EstudiantesService>.value(value: deps.estudiantes),
        Provider<RequisitosService>.value(value: deps.requisitos),
      ],
      child: MaterialApp(
        title: 'DinamikUTB',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AuthGate(),
      ),
    );
  }
}
