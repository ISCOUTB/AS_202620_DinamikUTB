
import 'dart:math' as math;
import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/network/api_exception.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/validators.dart';
import 'auth_controller.dart';

/// Pantalla de recuperación de contraseña.
class RecoverScreen extends StatefulWidget {
  const RecoverScreen({super.key});

  /// Ruta con revelado circular desde el enlace de recuperación.
  static Route<void> ruta({Offset? origen}) => PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 900),
        reverseTransitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const RecoverScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curva = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
            reverseCurve: Curves.easeInOutCubic,
          );

          final size = MediaQuery.sizeOf(context);
          final centro =
              origen ?? Offset(size.width / 2, size.height / 2);

          return AnimatedBuilder(
            animation: curva,
            child: child,
            builder: (context, child) => ClipPath(
              clipper: _CirculoRevela(curva.value, centro),
              child: child,
            ),
          );
        },
      );

  @override
  State<RecoverScreen> createState() => _RecoverScreenState();
}

class _CirculoRevela extends CustomClipper<Path> {
  _CirculoRevela(this.fraccion, this.centro);

  final double fraccion;
  final Offset centro;

  @override
  Path getClip(Size size) {
    final esquinas = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ];

    final radioMax =
        esquinas.map((e) => (e - centro).distance).reduce(math.max);

    return Path()
      ..addOval(
        Rect.fromCircle(
          center: centro,
          radius: radioMax * fraccion,
        ),
      );
  }

  @override
  bool shouldReclip(_CirculoRevela old) =>
      old.fraccion != fraccion || old.centro != centro;
}

class _RecoverScreenState extends State<RecoverScreen>
    with TickerProviderStateMixin {
  static const _escena = 'assets/images/recover_scene.jpg';

  final _formKey = GlobalKey<FormState>();
  final _correo = TextEditingController();

  bool _cargando = false;
  String? _error;
  String? _exito;

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );

  bool _iniciada = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_iniciada) return;
    _iniciada = true;

    if (MediaQuery.disableAnimationsOf(context)) {
      _intro.value = 1;
      _ambient.value = 0;
    } else {
      _intro.forward();
      _ambient.repeat();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _ambient.dispose();
    _correo.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = context.read<AuthController>();

    setState(() {
      _cargando = true;
      _error = null;
      _exito = null;
    });

    try {
      await auth.solicitarRecuperacion(_correo.text.trim());

      if (mounted) {
        setState(() {
          _exito =
              'Si el correo pertenece a una cuenta activa, recibirás instrucciones.';
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.statusCode == 503
              ? 'Este entorno no tiene correo de recuperación configurado. '
                  'Pide a administración que verifique tu identidad y emita un enlace temporal.'
              : e.message;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  double _v(double a, double b, [Curve c = Curves.easeOutCubic]) {
    return Interval(a, b, curve: c).transform(_intro.value);
  }

  // CORRECCIÓN: cada elemento escucha los cambios de la animación.
  Widget _aparece(double a, double b, Widget child) {
    return AnimatedBuilder(
      animation: _intro,
      child: child,
      builder: (context, child) {
        final v = _v(a, b);

        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, (1 - v) * 18),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;
    final ancha = w >= 900;

    final panel = _panel(
      context,
      ancha ? math.min(460.0, w * 0.42) : math.min(w - 32, 460.0),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFC673F),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFE13B44),
                  Color(0xFFFC673F),
                  Color(0xFFFD7A38),
                ],
              ),
            ),
          ),

          // Escena de fondo con movimiento suave.
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: Listenable.merge([_intro, _ambient]),
              builder: (context, _) {
                final asiento = lerpDouble(
                  1.14,
                  1.05,
                  Interval(0, 0.55, curve: Curves.easeOutCubic)
                      .transform(_intro.value),
                )!;

                final flota =
                    7 * math.sin(2 * math.pi * 3 * _ambient.value);

                final imagen = Transform.translate(
                  offset: Offset(0, flota),
                  child: Transform.scale(
                    scale: asiento,
                    alignment: Alignment.centerLeft,
                    child: Image.asset(
                      _escena,
                      fit: BoxFit.cover,
                      alignment: ancha
                          ? Alignment.centerLeft
                          : const Alignment(-0.64, -0.15),
                      filterQuality: FilterQuality.high,
                      errorBuilder: (context, error, stack) {
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                );

                if (ancha) {
                  return SizedBox.expand(child: imagen);
                }

                return Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    height: h * 0.52,
                    width: w,
                    child: ShaderMask(
                      blendMode: BlendMode.dstIn,
                      shaderCallback: (rect) {
                        return const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.65, 1.0],
                          colors: [
                            Colors.white,
                            Colors.transparent,
                          ],
                        ).createShader(rect);
                      },
                      child: ClipRect(child: imagen),
                    ),
                  ),
                );
              },
            ),
          ),

          // Panel de recuperación.
          SafeArea(
            child: ancha
                ? Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: math.max(40, w * 0.07),
                      ),
                      child: SingleChildScrollView(
                        child: panel,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      h * 0.34,
                      16,
                      24,
                    ),
                    child: Center(child: panel),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _panel(BuildContext context, double ancho) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: ancho,
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF2A0A3F).withValues(alpha: 0.62),
                const Color(0xFF45123F).withValues(alpha: 0.5),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.24),
            ),
          ),
          child: _contenido(context),
        ),
      ),
    );
  }

  Widget _contenido(BuildContext context) {
    const pasos = [
      (Icons.mail_outline, 'Escribes tu correo institucional'),
      (
        Icons.verified_user_outlined,
        'Administración verifica tu identidad'
      ),
      (
        Icons.link_rounded,
        'Recibes un enlace de un solo uso, válido 15 minutos'
      ),
    ];

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _aparece(
            0.50,
            0.70,
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    color: Color(0xFFFFC145),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          _aparece(
            0.56,
            0.76,
            Text(
              'Sin problema. Escribe tu correo institucional y te guiamos '
              'para recuperar el acceso de forma segura.',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                height: 1.45,
                color: Colors.white.withValues(alpha: 0.86),
              ),
            ),
          ),

          const SizedBox(height: 18),

          if (_error != null) ...[
            _Banner(
              mensaje: _error!,
              icono: Icons.error_outline,
              color: AppColors.danger,
              fondo: AppColors.dangerBg,
            ),
            const SizedBox(height: 14),
          ],

          if (_exito != null) ...[
            _Banner(
              mensaje: _exito!,
              icono: Icons.check_circle_outline,
              color: AppColors.successText,
              fondo: AppColors.successBg,
            ),
            const SizedBox(height: 14),
          ],

          _aparece(
            0.62,
            0.82,
            TextFormField(
              controller: _correo,
              enabled: !_cargando,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              maxLength: 254,
              onFieldSubmitted: (_) => _enviar(),
              validator: Validators.correoInstitucional,
              decoration: const InputDecoration(
                labelText: 'Correo institucional',
                hintText: 'nombre@utb.edu.co',
                prefixIcon: Icon(Icons.mail_outline),
                counterText: '',
              ),
            ),
          ),

          const SizedBox(height: 14),

          _aparece(
            0.70,
            0.90,
            FilledButton(
              onPressed: _cargando ? null : _enviar,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFC145),
                foregroundColor: const Color(0xFF2A0A3F),
                textStyle: const TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              child: _cargando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF2A0A3F),
                      ),
                    )
                  : const Text('Enviar instrucciones'),
            ),
          ),

          const SizedBox(height: 18),

          _aparece(
            0.80,
            1.0,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(
                  color: Colors.white.withValues(alpha: 0.18),
                  height: 1,
                ),
                const SizedBox(height: 14),

                Text(
                  '¿Cómo funciona?',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),

                const SizedBox(height: 10),

                for (final paso in pasos)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          paso.$1,
                          size: 18,
                          color: const Color(0xFFFFC145),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            paso.$2,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.5,
                              color: Colors.white.withValues(alpha: 0.82),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                Center(
                  child: TextButton.icon(
                    onPressed: () => Navigator.maybePop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFFFD27A),
                    ),
                    icon: const Icon(Icons.arrow_back, size: 17),
                    label: const Text(
                      'Volver al inicio de sesión',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.mensaje,
    required this.icono,
    required this.color,
    required this.fondo,
  });

  final String mensaje;
  final IconData icono;
  final Color color;
  final Color fondo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(icono, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensaje,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
