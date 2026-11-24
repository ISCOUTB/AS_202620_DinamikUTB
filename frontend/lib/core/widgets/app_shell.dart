import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/usuarios/auth_controller.dart';
import 'package:frontend/core/responsive/breakpoints.dart';
import 'package:frontend/core/theme/app_colors.dart';

class ShellDestination {
  const ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.builder,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final WidgetBuilder builder;
}

/// Navegación adaptativa: una sola barra inferior con solo iconos en todos
/// los tamaños (al pasar el mouse crecen), el logo UTB encabeza la página y
/// la cabecera conserva el título de la sección y el cierre de sesión.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.destinations});

  final List<ShellDestination> destinations;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _indice = 0;

  @override
  Widget build(BuildContext context) {
    final tamano = Breakpoints.of(context);
    final destinos = widget.destinations;
    final actual = destinos[_indice];
    final usuario = context.watch<AuthController>().usuario;
    final mostrarCorreo = MediaQuery.sizeOf(context).width >= 900;
    final cuerpo = IndexedStack(
      index: _indice,
      children: [for (final d in destinos) Builder(builder: d.builder)],
    );

    final barra = _BarraInferior(
      destinos: destinos,
      indice: _indice,
      onSeleccionar: (i) => setState(() => _indice = i),
    );

    if (tamano == ScreenSize.compact) {
      return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const _LogoUTB(alto: 30),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'DinamikUTB',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      actual.label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Cerrar sesión',
              color: AppColors.textMuted,
              icon: const Icon(Icons.logout),
              onPressed: () => context.read<AuthController>().cerrarSesion(),
            ),
          ],
        ),
        body: cuerpo,
        bottomNavigationBar: barra,
      );
    }

    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 64,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const _LogoUTB(alto: 42),
                const SizedBox(width: 12),
                Text(
                  actual.label,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                if (usuario != null) ...[
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: AppColors.surfaceLow,
                    child: Text(
                      usuario.email.isEmpty
                          ? '?'
                          : usuario.email[0].toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (mostrarCorreo) ...[
                    const SizedBox(width: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 240),
                      child: Text(
                        usuario.email,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ],
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Cerrar sesión',
                  color: AppColors.textMuted,
                  icon: const Icon(Icons.logout),
                  onPressed: () =>
                      context.read<AuthController>().cerrarSesion(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: cuerpo),
        ],
      ),
      bottomNavigationBar: barra,
    );
  }
}

/// Barra inferior con solo iconos; cada uno crece al recibir el mouse.
class _BarraInferior extends StatelessWidget {
  const _BarraInferior({
    required this.destinos,
    required this.indice,
    required this.onSeleccionar,
  });

  final List<ShellDestination> destinos;
  final int indice;
  final ValueChanged<int> onSeleccionar;

  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: indice,
    onDestinationSelected: onSeleccionar,
    labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
    destinations: [
      for (final d in destinos)
        NavigationDestination(
          icon: _IconoNav(icono: d.icon),
          selectedIcon: _IconoNav(icono: d.selectedIcon),
          label: d.label,
        ),
    ],
  );
}

/// Icono de la barra que se agranda (y vuelve) al pasar el mouse.
class _IconoNav extends StatefulWidget {
  const _IconoNav({required this.icono});

  final IconData icono;

  @override
  State<_IconoNav> createState() => _IconoNavState();
}

class _IconoNavState extends State<_IconoNav> {
  bool _sobrevuelo = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _sobrevuelo = true),
    onExit: (_) => setState(() => _sobrevuelo = false),
    child: AnimatedScale(
      scale: _sobrevuelo ? 1.35 : 1,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: Icon(widget.icono, size: 26),
    ),
  );
}

/// Logo UTB: las letras 3D junto al muñequito con birrete.
class _LogoUTB extends StatelessWidget {
  const _LogoUTB({required this.alto});

  final double alto;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/utb_logo.png',
    height: alto,
    fit: BoxFit.contain,
    // En las pruebas de widget el PNG no llega a decodificar; el hueco se
    // reserva igual para no mover el resto del diseño.
    errorBuilder: (context, error, stackTrace) => SizedBox(
      width: alto * 1.5,
      height: alto,
      child: const Center(
        child: Text(
          'UTB',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ),
  );
}
