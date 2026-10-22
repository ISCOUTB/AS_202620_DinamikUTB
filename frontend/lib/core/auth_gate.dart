import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../estudiantes/dashboard_screen.dart';
import '../estudiantes/estudiantes_service.dart';
import '../requisitos/gestion_requisitos_screen.dart';
import '../requisitos/requisitos_screen.dart';
import '../requisitos/requisitos_service.dart';
import '../usuarios/auth_controller.dart';
import '../usuarios/login_screen.dart';
import '../usuarios/models.dart';
import '../usuarios/perfil_screen.dart';
import 'widgets/app_shell.dart';

/// Muestra la pantalla según la sesión y el rol; el backend aplica los permisos.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final usuario = auth.usuario;
    switch (auth.status) {
      case AuthStatus.desconocido:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.noAutenticado:
        return const LoginScreen();
      case AuthStatus.autenticado:
        if (usuario == null) return const LoginScreen();
        return AppShell(
          key: ValueKey(usuario.id),
          destinations: _destinosPara(context, usuario),
        );
    }
  }

  List<ShellDestination> _destinosPara(BuildContext context, Usuario usuario) {
    final estudiantes = context.read<EstudiantesService>();
    final requisitos = context.read<RequisitosService>();
    final perfil = ShellDestination(
      label: 'Perfil',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      builder: (_) => PerfilScreen(usuario: usuario),
    );

    if (usuario.rol.esGestion) {
      return [
        ShellDestination(
          label: 'Gestión',
          icon: Icons.fact_check_outlined,
          selectedIcon: Icons.fact_check,
          builder: (_) => GestionRequisitosScreen(estudiantes: estudiantes, requisitos: requisitos),
        ),
        perfil,
      ];
    }

    final codigo = usuario.codigoEstudiantil;
    Widget sinCodigo(BuildContext _) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Tu cuenta no tiene un código estudiantil asociado. Contacta a coordinación.',
              textAlign: TextAlign.center,
            ),
          ),
        );
    return [
      ShellDestination(
        label: 'Inicio',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        builder: codigo == null
            ? sinCodigo
            : (_) => DashboardScreen(
                  estudiantes: estudiantes,
                  requisitos: requisitos,
                  codigoEstudiantil: codigo,
                ),
      ),
      ShellDestination(
        label: 'Requisitos',
        icon: Icons.checklist_outlined,
        selectedIcon: Icons.checklist,
        builder: codigo == null
            ? sinCodigo
            : (_) => RequisitosScreen(service: requisitos, estudianteId: codigo),
      ),
      perfil,
    ];
  }
}
