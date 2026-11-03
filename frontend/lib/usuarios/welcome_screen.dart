import 'dart:math' as math;
import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:flutter/material.dart';

/// Pantalla de entrada
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.onIniciar});

  final VoidCallback onIniciar;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  static const _asset = 'assets/images/characters_hero.png';
  static const _imgW = 1672.0;
  static const _imgH = 941.0;

  /// Altura (fracción de la imagen) del punto de enfoque: entre la cara
  /// del muñeco de gafas y el portátil.
  static const _focoY = 0.80;

  // Cámara: los primeros 20 % son una pausa para ver al muñeco grande.
  late final AnimationController _camara = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3400),
  );
  late final AnimationController _ui = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _camara,
    curve: const Interval(0.2, 1.0, curve: Curves.easeInOutCubic),
  );

  bool _iniciada = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciada) return;
    _iniciada = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _saltar();
    } else {
      _camara.forward().whenComplete(() {
        if (mounted) _ui.forward();
      });
    }
  }

  @override
  void dispose() {
    _camara.dispose();
    _ui.dispose();
    super.dispose();
  }

  void _saltar() {
    if (_ui.isCompleted) return;
    _camara.value = 1;
    _ui.value = 1;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;
    final compact = w < 600;

    // Escenario con los muñecos, pegado abajo.
    final stageH = compact ? h * 0.58 : h * 0.86;
    final cover = math.max(w / _imgW, stageH / _imgH);
    final drawnH = _imgH * cover;

    final pFinal = Offset(w / 2, (h - drawnH) + _focoY * drawnH);
    final foco = Offset(w / 2, h * 0.62);
    final s0 = math.max(
      compact ? 3.0 : 2.4,
      (h - foco.dy) / ((1 - _focoY) * drawnH) + 0.05,
    );

    final panelW = math.min(440.0, w - 48);
    final titulo = math
        .min(math.min(w * 0.2, h * 0.115), (panelW - 56) / 3.3)
        .clamp(40.0, 96.0);

    return Scaffold(
      backgroundColor: const Color(0xFF3A0090),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _saltar,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF3A0090), Color(0xFF6A00D8)],
                ),
              ),
            ),

            // Cámara: zoom out desde el muñeco del portátil.
            AnimatedBuilder(
              animation: _t,
              builder: (context, child) {
                final t = _t.value;
                return Transform.translate(
                  offset: Offset.lerp(foco - pFinal, Offset.zero, t)!,
                  child: Transform.scale(
                    scale: lerpDouble(s0, 1, t)!,
                    alignment: Alignment(
                      pFinal.dx / w * 2 - 1,
                      pFinal.dy / h * 2 - 1,
                    ),
                    child: child,
                  ),
                );
              },
              child: RepaintBoundary(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: w,
                    height: stageH,
                    child: ShaderMask(
                      blendMode: BlendMode.dstIn,
                      shaderCallback: (rect) => const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.0, 0.35],
                        colors: [Colors.transparent, Colors.white],
                      ).createShader(rect),
                      child: Image.asset(
                        _asset,
                        fit: BoxFit.cover,
                        alignment: Alignment.bottomCenter,
                        filterQuality: FilterQuality.high,
                        frameBuilder: (context, child, frame, sync) =>
                            AnimatedOpacity(
                          opacity: (frame != null || sync) ? 1 : 0,
                          duration: const Duration(milliseconds: 400),
                          child: child,
                        ),
                        errorBuilder: (context, error, stack) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Insignia + panel desplegable, centrados en toda la página.
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Entrada(
                          parent: _ui,
                          inicio: 0.0,
                          fin: 0.12,
                          child: const _Insignia(),
                        ),
                        const SizedBox(height: 10),
                        _PanelDesplegable(
                          parent: _ui,
                          inicio: 0.1,
                          fin: 0.55,
                          ancho: panelW,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _Entrada(
                                parent: _ui,
                                inicio: 0.45,
                                fin: 0.65,
                                child: _palabra('DINA', titulo, Colors.white),
                              ),
                              _Entrada(
                                parent: _ui,
                                inicio: 0.55,
                                fin: 0.75,
                                child: ShaderMask(
                                  blendMode: BlendMode.srcIn,
                                  shaderCallback: (r) => const LinearGradient(
                                    colors: [
                                      Color(0xFF7DD3FC),
                                      Color(0xFFA5B4FC),
                                      Color(0xFFC4B5FD),
                                    ],
                                  ).createShader(r),
                                  child: _palabra('MIK', titulo, Colors.white),
                                ),
                              ),
                              _Entrada(
                                parent: _ui,
                                inicio: 0.65,
                                fin: 0.85,
                                child: _palabra(
                                  'UTB',
                                  titulo,
                                  Colors.white.withValues(alpha: 0.45),
                                ),
                              ),
                              const SizedBox(height: 22),
                              _Entrada(
                                parent: _ui,
                                inicio: 0.75,
                                fin: 0.92,
                                child: Column(
                                  children: [
                                    Text(
                                      '¿Aún no sabes qué te falta para\ngraduarte?',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: compact ? 17 : 20,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        height: 1.25,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tu ruta de grado clara, sin sorpresas ni enredos.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: compact ? 12.5 : 14,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF7DD3FC),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 26),
                              _Entrada(
                                parent: _ui,
                                inicio: 0.85,
                                fin: 1.0,
                                child: _Boton(onTap: widget.onIniciar),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _palabra(String texto, double size, Color color) => Text(
        texto,
        style: TextStyle(
          fontFamily: 'Syne',
          fontSize: size,
          fontWeight: FontWeight.w800,
          height: 0.92,
          letterSpacing: 3,
          color: color,
        ),
      );
}

/// Panel de vidrio que nace de la insignia: crece hacia abajo y se ensancha.
/// Es semitransparente (tinte morado + desenfoque leve) para dejar ver el fondo.
class _PanelDesplegable extends StatelessWidget {
  const _PanelDesplegable({
    required this.parent,
    required this.inicio,
    required this.fin,
    required this.ancho,
    required this.child,
  });

  final Animation<double> parent;
  final double inicio;
  final double fin;
  final double ancho;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curva = Interval(inicio, fin, curve: Curves.easeOutCubic);
    return AnimatedBuilder(
      animation: parent,
      child: child,
      builder: (context, child) {
        final v = curva.transform(parent.value);
        return ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: v,
              widthFactor: lerpDouble(0.55, 1, v),
              child: Container(
                width: ancho,
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 30),
                decoration: BoxDecoration(
                  // Sube/baja el alpha (0.0 a 1.0) para más o menos transparencia.
                  color: const Color(0xFF1A0640).withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Aparece con fundido y un pequeño desplazamiento hacia arriba.
class _Entrada extends StatelessWidget {
  const _Entrada({
    required this.parent,
    required this.inicio,
    required this.fin,
    required this.child,
  });

  final Animation<double> parent;
  final double inicio;
  final double fin;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curva = Interval(inicio, fin, curve: Curves.easeOutCubic);
    return AnimatedBuilder(
      animation: parent,
      child: child,
      builder: (context, child) {
        final v = curva.transform(parent.value);
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, (1 - v) * 22),
            child: child,
          ),
        );
      },
    );
  }
}

class _Insignia extends StatelessWidget {
  const _Insignia();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF140D2B).withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.public_rounded, size: 14, color: Color(0xFF7DD3FC)),
            SizedBox(width: 8),
            Text(
              'PORTAL OFICIAL DE LA UTB',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: Color(0xFFE2E8F0),
              ),
            ),
          ],
        ),
      );
}

class _Boton extends StatelessWidget {
  const _Boton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [Color(0xFFC4B5FD), Color(0xFF818CF8), Color(0xFF38BDF8)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
              blurRadius: 28,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: onTap,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 44, vertical: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Iniciar sesión',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F0529),
                    ),
                  ),
                  SizedBox(width: 10),
                  Icon(Icons.arrow_forward_rounded,
                      size: 19, color: Color(0xFF0F0529)),
                ],
              ),
            ),
          ),
        ),
      );
}
