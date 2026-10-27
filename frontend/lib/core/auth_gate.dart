import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/administracion/admin_panel_screen.dart';
import 'package:frontend/administracion/service/admin_service.dart';
import 'package:frontend/curriculo/malla_screen.dart';
import 'package:frontend/curriculo/malla_service.dart';
import 'package:frontend/estudiantes/dashboard_screen.dart';
import 'package:frontend/estudiantes/estudiantes_service.dart';
import 'package:frontend/requisitos/gestion_requisitos_screen.dart';
import 'package:frontend/requisitos/requisitos_screen.dart';
import 'package:frontend/requisitos/requisitos_service.dart';
import 'package:frontend/usuarios/auth_controller.dart';
import 'package:frontend/usuarios/login_screen.dart';
import 'package:frontend/usuarios/models.dart';
import 'package:frontend/usuarios/perfil_screen.dart';
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
        if (usuario.rol == Rol.administrador) {
          return AdminPanelScreen(
            key: ValueKey(usuario.id),
            email: usuario.email,
            onLogout: () => context.read<AuthController>().cerrarSesion(),
            service: context.read<AdminService>(),
          );
        }
        return AppShell(
          key: ValueKey(usuario.id),
          destinations: _destinosPara(context, usuario),
        );
    }
  }

  List<ShellDestination> _destinosPara(BuildContext context, Usuario usuario) {
    final estudiantes = context.read<EstudiantesService>();
    final requisitos = context.read<RequisitosService>();
    final malla = context.read<MallaService>();
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
          builder: (_) => GestionRequisitosScreen(
            estudiantes: estudiantes,
            requisitos: requisitos,
            administracion: context.read<AdminService>(),
          ),
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
    Widget sinPrograma(BuildContext _) => const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Tu cuenta no tiene un programa académico asociado para consultar la malla.',
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
        label: 'Malla',
        icon: Icons.account_tree_outlined,
        selectedIcon: Icons.account_tree,
        builder: usuario.programa == null
            ? sinPrograma
            : (_) => MallaScreen(
                service: malla,
                programa: usuario.programa!,
                semestreActual: usuario.semestre,
              ),
      ),
      ShellDestination(
        label: 'Requisitos',
        icon: Icons.checklist_outlined,
        selectedIcon: Icons.checklist,
        builder: codigo == null
            ? sinCodigo
            : (_) =>
                  RequisitosScreen(service: requisitos, estudianteId: codigo),
      ),
      perfil,
    ];
  }
}
