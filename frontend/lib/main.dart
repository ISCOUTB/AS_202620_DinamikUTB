import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'core/auth_gate.dart';
import 'core/config.dart';
import 'core/network/api_client.dart';
import 'core/not_found_screen.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/app_theme.dart';
import 'administracion/service/admin_service.dart';
import 'curriculo/malla_service.dart';
import 'estudiantes/estudiantes_service.dart';
import 'requisitos/requisitos_service.dart';
import 'usuarios/auth_controller.dart';
import 'usuarios/auth_service.dart';
import 'usuarios/account_screen.dart';
import 'usuarios/login_screen.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

/// Construye las dependencias compartidas de la aplicación.
class AppDependencias {
  AppDependencias._(
    this.api,
    this.auth,
    this.estudiantes,
    this.requisitos,
    this.malla,
  );

  factory AppDependencias.crear({
    String baseUrl = apiBaseUrl,
    TokenStorage? storage,
    http.Client? client,
  }) {
    final almacen = storage ?? SecureTokenStorage();
    final api = ApiClient(
      baseUrl: baseUrl,
      tokenStorage: almacen,
      client: client,
    );
    final auth = AuthController(service: AuthService(api), storage: almacen);
    api.onUnauthorized = () =>
        auth.cerrarSesion(); // sesión vencida → vuelve al login
    return AppDependencias._(
      api,
      auth,
      EstudiantesService(api),
      RequisitosService(api),
      MallaService(api),
    );
  }

  final ApiClient api;
  final AuthController auth;
  final EstudiantesService estudiantes;
  final RequisitosService requisitos;
  final MallaService malla;
}

void main() {
  validarConfiguracion();
  runApp(
    DinamikApp(
      dependencias: AppDependencias.crear(),
      resetToken: _tokenRecuperacion(Uri.base),
    ),
  );
}

String? _tokenRecuperacion(Uri uri) {
  final queryToken = uri.queryParameters['reset_token'];
  if (queryToken != null) return queryToken;
  final fragment = uri.fragment;
  if (fragment.isEmpty) return null;
  return Uri.splitQueryString(fragment)['reset_token'];
}

class DinamikApp extends StatefulWidget {
  const DinamikApp({super.key, required this.dependencias, this.resetToken});

  final AppDependencias dependencias;
  final String? resetToken;

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
        Provider<ApiClient>.value(value: deps.api),
        Provider<AdminService>.value(value: AdminService(deps.api)),
        Provider<EstudiantesService>.value(value: deps.estudiantes),
        Provider<RequisitosService>.value(value: deps.requisitos),
        Provider<MallaService>.value(value: deps.malla),
      ],
      child: MaterialApp(
        title: 'DinamikUTB',
        navigatorKey: _navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        onUnknownRoute: (settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const NotFoundScreen(),
        ),
        home: widget.resetToken == null
            ? const AuthGate()
            : AccountScreen(
                page: AccountPage.restablecer,
                token: widget.resetToken!,
                onCompleted: () {
                  _navigatorKey.currentState?.pushAndRemoveUntil(
                    MaterialPageRoute<void>(
                      builder: (_) => const LoginScreen(),
                    ),
                    (_) => false,
                  );
                },
              ),
      ),
    );
  }
}
