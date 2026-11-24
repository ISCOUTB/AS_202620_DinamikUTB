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

  /// Secciones con fondo oscuro: la barra inferior se aclara para contrastar.
  /// Las demás tienen fondo claro y la barra se oscurece. Así el icono
  /// seleccionado siempre se distingue (nunca blanco sobre blanco).
  static bool _fondoEsOscuro(String etiqueta) =>
      etiqueta == 'Perfil' || etiqueta == 'Malla' || etiqueta == 'Requisitos';

  @override
  Widget build(BuildContext context) {
    final tamano = Breakpoints.of(context);
    final destinos = widget.destinations;
    final actual = destinos[_indice];
    final usuario = context.watch<AuthController>().usuario;
    final mostrarCorreo = MediaQuery.sizeOf(context).width >= 900;
    final fondoOscuro = _fondoEsOscuro(actual.label);
    final cuerpo = IndexedStack(
      index: _indice,
      children: [for (final d in destinos) Builder(builder: d.builder)],
    );

    final barra = _BarraInferior(
      destinos: destinos,
      indice: _indice,
      fondoOscuro: fondoOscuro,
      onSeleccionar: (i) => setState(() => _indice = i),
    );

    if (tamano == ScreenSize.compact) {
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: 54,
          titleSpacing: 14,
          title: Row(
            children: [
              const _LogoUTB(alto: 26),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShaderMask(
                      shaderCallback: (rect) => const LinearGradient(
                        colors: [
                          Color(0xFFDB2777),
                          Color(0xFF7C3AED),
                          Color(0xFF0284C7),
                        ],
                      ).createShader(rect),
                      blendMode: BlendMode.srcIn,
                      child: const Text(
                        'DinamikUTB',
                        style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFFF472B6), Color(0xFF38BDF8)],
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            actual.label,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.border),
              ),
              child: IconButton(
                tooltip: 'Cerrar sesión',
                color: AppColors.navy,
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 34,
                  height: 34,
                ),
                icon: const Icon(Icons.logout_rounded),
                onPressed: () => context.read<AuthController>().cerrarSesion(),
              ),
            ),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(2),
            child: _LineaAurora(),
          ),
        ),
        body: cuerpo,
        bottomNavigationBar: barra,
      );
    }

    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFF4F6FF),
                  Color(0xFFFFF4FA),
                ],
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Brumas suaves de la identidad de la app (recortadas al alto
                // de la cabecera para no teñir el contenido de abajo).
                Positioned.fill(
                  child: ClipRect(
                    child: Stack(
                      fit: StackFit.expand,
                      children: const [
                        Positioned(
                          top: -54,
                          right: 210,
                          child: _Bruma(color: Color(0x33A855F7), tamano: 130),
                        ),
                        Positioned(
                          bottom: -70,
                          left: 240,
                          child: _Bruma(color: Color(0x2AF472B6), tamano: 120),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _SombraLinea(child: _LineaAurora()),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      const _LogoUTB(alto: 34),
                      const SizedBox(width: 11),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ShaderMask(
                            shaderCallback: (rect) => const LinearGradient(
                              colors: [
                                Color(0xFFDB2777),
                                Color(0xFF7C3AED),
                                Color(0xFF0284C7),
                              ],
                            ).createShader(rect),
                            blendMode: BlendMode.srcIn,
                            child: const Text(
                              'DinamikUTB',
                              style: TextStyle(
                                fontFamily: 'Syne',
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLow,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFFF472B6),
                                        Color(0xFF38BDF8),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  actual.label,
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    color: AppColors.textMuted,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (usuario != null)
                        _ChipUsuario(
                          inicial: usuario.email.isEmpty
                              ? '?'
                              : usuario.email[0].toUpperCase(),
                          correo: mostrarCorreo ? usuario.email : null,
                          rol: mostrarCorreo ? usuario.rol.etiqueta : null,
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Cerrar sesión',
                        color: AppColors.textMuted,
                        hoverColor: const Color(0xFFFFEDF5),
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 34,
                          height: 34,
                        ),
                        icon: const Icon(Icons.logout_rounded),
                        onPressed: () =>
                            context.read<AuthController>().cerrarSesion(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: cuerpo),
        ],
      ),
      bottomNavigationBar: barra,
    );
  }
}

/// Sombra suave bajo la línea aurora de la cabecera.
class _SombraLinea extends StatelessWidget {
  const _SombraLinea({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      boxShadow: [
        BoxShadow(
          color: AppColors.navy.withValues(alpha: 0.12),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );
}

/// Bruma circular para dar profundidad al fondo de la cabecera.
class _Bruma extends StatelessWidget {
  const _Bruma({required this.color, required this.tamano});

  final Color color;
  final double tamano;

  @override
  Widget build(BuildContext context) => Container(
    width: tamano,
    height: tamano,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
    ),
  );
}

/// Perfil del usuario en la cabecera: avatar con degradado y correo.
class _ChipUsuario extends StatelessWidget {
  const _ChipUsuario({required this.inicial, this.correo, this.rol});

  final String inicial;
  final String? correo;
  final String? rol;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(4, 4, correo == null ? 4 : 11, 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: AppColors.border),
      boxShadow: [
        BoxShadow(
          color: AppColors.navy.withValues(alpha: 0.06),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppColors.navy, AppColors.cyan],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Text(
              inicial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ),
        if (correo != null) ...[
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: Text(
                  correo!,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    color: AppColors.navy,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              if (rol != null)
                Text(
                  rol!,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    color: AppColors.textMuted,
                    fontSize: 10.5,
                  ),
                ),
            ],
          ),
        ],
      ],
    ),
  );
}

/// Línea de identidad (rosa → morado → celeste) al pie de la cabecera.
class _LineaAurora extends StatelessWidget {
  const _LineaAurora();

  @override
  Widget build(BuildContext context) => Container(
    height: 2,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Color(0xFFF472B6),
          Color(0xFFA855F7),
          Color(0xFF7C3AED),
          Color(0xFF38BDF8),
        ],
      ),
    ),
  );
}

/// Barra inferior con solo iconos; cada uno crece al recibir el mouse.
/// El tono responde al fondo de la sección: fondo oscuro ⇒ barra clara,
/// fondo claro ⇒ barra oscura (nunca icono blanco sobre barra blanca).
class _BarraInferior extends StatelessWidget {
  const _BarraInferior({
    required this.destinos,
    required this.indice,
    required this.fondoOscuro,
    required this.onSeleccionar,
  });

  final List<ShellDestination> destinos;
  final int indice;
  final bool fondoOscuro;
  final ValueChanged<int> onSeleccionar;

  @override
  Widget build(BuildContext context) {
    final barraClara = fondoOscuro;
    final fondo = barraClara ? const Color(0xFFF7F8FD) : AppColors.navy;
    final indicador = barraClara
        ? AppColors.navy.withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 0.16);
    final borde = barraClara ? AppColors.border : Colors.white24;

    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: borde)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: barraClara ? 0.07 : 0.10),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: indice,
        onDestinationSelected: onSeleccionar,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        height: 56,
        backgroundColor: fondo,
        surfaceTintColor: Colors.transparent,
        indicatorColor: indicador,
        elevation: 0,
        destinations: [
          for (final d in destinos)
            NavigationDestination(
              icon: _IconoNav(icono: d.icon),
              selectedIcon: _IconoNav(icono: d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }
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
      scale: _sobrevuelo ? 1.12 : 1,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      child: Icon(widget.icono, size: 21),
    ),
  );
}

/// Logo UTB: la mascota 3D con birrete y gafas de la universidad.
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
      width: alto * 1.05,
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
