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
        appBar: AppBar(
          title: Row(
            children: [
              _BrandIcon(size: 32),
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
        ),
        body: cuerpo,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _indice,
          onDestinationSelected: (i) => setState(() => _indice = i),
          destinations: [
            for (final d in destinos)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
              ),
          ],
        ),
      );
    }

    final extendido = tamano == ScreenSize.expanded;
    final usuario = context.watch<AuthController>().usuario;
    final mostrarCorreo = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: Colors.white,
            extended: extendido,
            labelType: extendido ? null : NavigationRailLabelType.selected,
            selectedIndex: _indice,
            onDestinationSelected: (i) => setState(() => _indice = i),
            indicatorColor: AppColors.surfaceLow,
            selectedIconTheme: const IconThemeData(color: AppColors.navy),
            unselectedIconTheme: const IconThemeData(
              color: AppColors.textMuted,
            ),
            selectedLabelTextStyle: const TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelTextStyle: const TextStyle(
              color: AppColors.textMuted,
            ),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _BrandIcon(size: 36),
                  if (extendido) ...[
                    const SizedBox(width: 10),
                    const Text(
                      'DinamikUTB',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
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
                    color: AppColors.textMuted,
                    icon: const Icon(Icons.logout),
                    onPressed: () =>
                        context.read<AuthController>().cerrarSesion(),
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
                      Text(
                        actual.label,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
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
                              style: const TextStyle(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ],
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

class _BrandIcon extends StatelessWidget {
  const _BrandIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: AppColors.navy,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(
      Icons.school_rounded,
      color: AppColors.cyanLight,
      size: size * 0.58,
    ),
  );
}
