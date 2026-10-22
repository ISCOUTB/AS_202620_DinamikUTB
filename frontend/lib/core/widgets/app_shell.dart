import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../usuarios/auth_controller.dart';
import '../responsive/breakpoints.dart';
import '../theme/app_colors.dart';

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

/// Adapta la navegación a móvil, tableta y escritorio.
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
    final cuerpo = IndexedStack(
      index: _indice,
      children: [for (final d in destinos) Builder(builder: d.builder)],
    );

    if (tamano == ScreenSize.compact) {
      return Scaffold(
        appBar: AppBar(title: Text(actual.label)),
        body: cuerpo,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _indice,
          onDestinationSelected: (i) => setState(() => _indice = i),
          destinations: [
            for (final d in destinos)
              NavigationDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: d.label),
          ],
        ),
      );
    }

    final extendido = tamano == ScreenSize.expanded;
    final usuario = context.watch<AuthController>().usuario;
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: AppColors.navy,
            extended: extendido,
            labelType: extendido ? null : NavigationRailLabelType.selected,
            selectedIndex: _indice,
            onDestinationSelected: (i) => setState(() => _indice = i),
            indicatorColor: AppColors.cyan,
            selectedIconTheme: const IconThemeData(color: Colors.white),
            unselectedIconTheme: const IconThemeData(color: Colors.white70),
            selectedLabelTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            unselectedLabelTextStyle: const TextStyle(color: Colors.white70),
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.school_rounded, color: AppColors.gold, size: 32),
                  SizedBox(width: 8),
                ],
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: IconButton(
                    tooltip: 'Cerrar sesión',
                    color: Colors.white70,
                    icon: const Icon(Icons.logout),
                    onPressed: () => context.read<AuthController>().cerrarSesion(),
                  ),
                ),
              ),
            ),
            destinations: [
              for (final d in destinos)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: Text(d.label),
                ),
            ],
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 64,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Text(actual.label,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const Spacer(),
                      if (usuario != null)
                        Text(usuario.email, style: const TextStyle(color: AppColors.textMuted)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(child: cuerpo),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
