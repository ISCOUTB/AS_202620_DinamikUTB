import 'dart:math' as math;
import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/network/api_exception.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/validators.dart';
import 'auth_controller.dart';
import 'recover_screen.dart';

/// Inicio de sesión.
///
/// Coreografía de entrada (una sola secuencia, ~3 s):
/// 1. El muñeco sube desde detrás del panel de cristal, centrado.
/// 2. El conjunto se desplaza a la derecha.
/// 3. En la izquierda se despliega el rectángulo con el título.
/// Todo lo ambiental (orbes, íconos flotantes, garabatos) se mueve en bucle
/// lento y se desactiva si el sistema pide reducir animaciones.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  static const _charAsset = 'assets/images/login_character.png';
  static const _swirlAsset = 'assets/images/login_swirl.png';
  static const _sparksAsset = 'assets/images/login_sparks.png';
  static const _charW = 673.0;
  static const _charH = 291.0;

  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _ocultar = true;
  bool _cargando = false;
  bool _recordarme = false;
  String? _error;

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3400),
  );
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  );
  bool _iniciada = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciada) return;
    _iniciada = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _intro.value = 1;
    } else {
      _intro.forward();
      _ambient.repeat();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _ambient.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthController>();
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await auth.iniciarSesion(
        _email.text,
        _password.text,
        recordar: _recordarme,
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  /// Progreso (0..1) de un tramo de la animación de entrada.
  double _v(double a, double b, [Curve c = Curves.easeOutCubic]) =>
      Interval(a, b, curve: c).transform(_intro.value);

  Widget _aparece(
    double a,
    double b,
    Widget child, {
    Offset desde = const Offset(-24, 0),
  }) {
    final v = _v(a, b);
    return Opacity(
      opacity: v,
      child: Transform.translate(
        offset: Offset(desde.dx * (1 - v), desde.dy * (1 - v)),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final ancha = size.width >= 900;
    final formulario = _formulario(context);

    return Scaffold(
      backgroundColor: const Color(0xFF3A0090),
      body: Stack(
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
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _ambient,
              builder: (context, _) => _ambiente(_ambient.value, ancha),
            ),
          ),
          SafeArea(
            child: AnimatedBuilder(
              animation: _intro,
              child: formulario,
              builder: (context, form) => ancha
                  ? _vistaAncha(size, form!)
                  : _vistaCompacta(size, form!),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Ambiente ─────────────────────────

  Widget _ambiente(double t, bool ancha) {
    const orbes = [
      (-0.9, -0.8, 380.0, Color(0xFFA855F7), 0.0),
      (0.95, -0.5, 320.0, Color(0xFF3B82F6), 0.3),
      (-0.7, 0.95, 340.0, Color(0xFFD946EF), 0.6),
      (0.85, 0.9, 400.0, Color(0xFF7C3AED), 0.15),
    ];
    const chips = [
      (Icons.workspace_premium_outlined, 0.97, -0.88, 0.0),
      (Icons.checklist_rounded, 0.97, 0.88, 0.35),
      (Icons.school_rounded, 0.2, 0.92, 0.7),
    ];
    const tau = 2 * math.pi;
    return Stack(
      fit: StackFit.expand,
      children: [
        for (final o in orbes)
          Align(
            alignment: Alignment(
              o.$1 + 0.05 * math.sin(tau * (t + o.$5)),
              o.$2 + 0.05 * math.cos(tau * (t + o.$5)),
            ),
            child: Container(
              width: o.$3,
              height: o.$3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    o.$4.withValues(alpha: 0.38),
                    o.$4.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        if (ancha)
          for (final c in chips)
            Align(
              alignment: Alignment(
                c.$2,
                c.$3 + 0.025 * math.sin(tau * 2 * (t + c.$4)),
              ),
              child: Container(
                width: 46,
                height: 46,
                margin: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                child: Icon(
                  c.$1,
                  size: 22,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ),
      ],
    );
  }

  // ───────────────────────── Vistas ─────────────────────────

  Widget _vistaAncha(Size size, Widget form) {
    final w = size.width;
    final h = size.height;
    const margen = 40.0;
    const separacion = 28.0;
    final lw = (w * 0.40).clamp(400.0, 600.0);
    final inicioDerecha = margen + lw + separacion;
    final disponible = w - margen - inicioDerecha;
    final sw = math.min(500.0, disponible);
    final centroFinal = inicioDerecha + disponible / 2;
    // El conjunto muñeco + formulario nace centrado y se desliza a la derecha.
    final desliza = _v(0.32, 0.72, Curves.easeInOutCubic);
    final dx = (w / 2 - centroFinal) * (1 - desliza);

    return Stack(
      children: [
        Positioned(
          left: margen,
          top: 0,
          bottom: 0,
          width: lw,
          child: Center(child: _panelIzquierdo(lw, h)),
        ),
        Positioned(
          left: inicioDerecha,
          right: margen,
          top: 0,
          bottom: 0,
          child: Transform.translate(
            offset: Offset(dx, 0),
            child: Center(
              child: SingleChildScrollView(child: _escenario(sw, form)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _vistaCompacta(Size size, Widget form) {
    final sw = math.min(size.width - 32, 460.0);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Center(
        child: Column(
          children: [
            _aparece(
              0.30,
              0.60,
              desde: const Offset(0, -20),
              Column(
                children: [
                  const _EtiquetaPortal(),
                  const SizedBox(height: 14),
                  const Text(
                    'Inicio de sesión',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'DinamikUTB',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF7DD3FC),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Ingresa tus credenciales institucionales.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _escenario(sw, form),
          ],
        ),
      ),
    );
  }

  // ───────────────────── Rectángulo izquierdo ─────────────────────

  Widget _panelIzquierdo(double lw, double h) {
    final v = _v(0.42, 0.80, Curves.easeInOutCubic);
    final ph = math.min(h - 64, 660.0);
    final titulo = (lw * 0.125).clamp(38.0, 64.0);
    const puntos = [
      (Icons.flag_outlined, 'Conoce qué requisitos de grado ya cumpliste'),
      (Icons.timelapse_outlined, 'Detecta a tiempo lo que te falta'),
      (Icons.lock_outline, 'Tu información académica, solo para ti'),
    ];

    return SizedBox(
      width: lw,
      height: ph,
      child: Align(
        alignment: Alignment.centerLeft,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: v,
              heightFactor: 1,
              child: Container(
                width: lw,
                height: ph,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF2A0F5E).withValues(alpha: 0.6),
                      const Color(0xFF3B1590).withValues(alpha: 0.42),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(40),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: ph - 80),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _aparece(0.55, 0.72, const _EtiquetaPortal()),
                        const SizedBox(height: 24),
                        _aparece(
                          0.60,
                          0.80,
                          Text(
                            'Inicio de\nsesión',
                            style: TextStyle(
                              fontFamily: 'Syne',
                              fontSize: titulo,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 0.98,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _aparece(
                          0.66,
                          0.84,
                          const Text(
                            'DinamikUTB',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF7DD3FC),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        _aparece(
                          0.70,
                          0.88,
                          Text(
                            'Ingresa tus credenciales institucionales para '
                            'consultar tu avance hacia el grado.',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16,
                              height: 1.5,
                              color: Colors.white.withValues(alpha: 0.86),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        for (var i = 0; i < puntos.length; i++)
                          _aparece(
                            0.74 + i * 0.05,
                            0.92 + i * 0.03,
                            Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                    child: Icon(
                                      puntos[i].$1,
                                      size: 20,
                                      color: const Color(0xFF7DD3FC),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      puntos[i].$2,
                                      style: const TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        _aparece(
                          0.88,
                          1.0,
                          Text(
                            'Universidad Tecnológica de Bolívar',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────── Muñeco + panel de cristal ─────────────────

  Widget _escenario(double sw, Widget form) {
    final imgW = sw * 0.80;
    final imgH = imgW * _charH / _charW;
    final sube = _v(0.05, 0.40, Curves.easeOutBack);
    final panel = _v(0.0, 0.30);
    final contenido = _v(0.24, 0.52);
    final pop = _v(0.50, 0.80, Curves.easeOutBack);

    return SizedBox(
      width: sw,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Muñeco: sube desde detrás del panel y se asoma agarrando el borde.
          Positioned(
            top: 0,
            left: (sw - imgW) / 2,
            width: imgW,
            child: Transform.translate(
              offset: Offset(0, (1 - sube) * imgH * 0.85),
              child: Image.asset(
                _charAsset,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stack) =>
                    const SizedBox.shrink(),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: imgH - 6),
            child: Transform.translate(
              offset: Offset(0, (1 - panel) * 30),
              child: Transform.scale(
                scale: lerpDouble(0.94, 1, panel)!,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      width: sw,
                      padding: const EdgeInsets.fromLTRB(28, 28, 28, 22),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF2A0F5E).withValues(alpha: 0.62),
                            const Color(0xFF3B1590).withValues(alpha: 0.48),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Opacity(opacity: contenido, child: form),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Garabato y chispas: aparecen con un "pop" y se mecen despacio.
          Positioned(
            top: -imgH * 0.02,
            left: sw / 2 - imgW * 0.64,
            child: AnimatedBuilder(
              animation: _ambient,
              builder: (context, child) => Transform.rotate(
                angle: 0.1 * math.sin(2 * math.pi * 3 * _ambient.value),
                child: Transform.scale(scale: pop, child: child),
              ),
              child: Image.asset(
                _swirlAsset,
                width: imgW * 0.17,
                errorBuilder: (context, error, stack) =>
                    const SizedBox.shrink(),
              ),
            ),
          ),
          Positioned(
            top: -imgH * 0.06,
            left: sw / 2 + imgW * 0.30,
            child: AnimatedBuilder(
              animation: _ambient,
              builder: (context, child) => Transform.scale(
                scale:
                    pop *
                    (1 + 0.07 * math.sin(2 * math.pi * 6 * _ambient.value)),
                child: child,
              ),
              child: Image.asset(
                _sparksAsset,
                width: imgW * 0.13,
                errorBuilder: (context, error, stack) =>
                    const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Formulario ─────────────────────────

  Widget _formulario(BuildContext context) {
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Accede a tu cuenta',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Usa tu correo y contraseña institucionales.',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 18),
            if (_error != null) ...[
              _Aviso(mensaje: _error!),
              const SizedBox(height: 14),
            ],
            TextFormField(
              controller: _email,
              enabled: !_cargando,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [
                AutofillHints.username,
                AutofillHints.email,
              ],
              autocorrect: false,
              maxLength: 254,
              validator: Validators.email,
              decoration: const InputDecoration(
                labelText: 'Correo',
                prefixIcon: Icon(Icons.mail_outline),
                counterText: '',
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _password,
              enabled: !_cargando,
              keyboardType: TextInputType.visiblePassword,
              obscureText: _ocultar,
              autocorrect: false,
              enableSuggestions: false,
              maxLength: 128,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _enviar(),
              validator: Validators.password,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: const Icon(Icons.lock_outline),
                counterText: '',
                suffixIcon: IconButton(
                  tooltip: _ocultar
                      ? 'Mostrar contraseña'
                      : 'Ocultar contraseña',
                  icon: Icon(
                    _ocultar
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _ocultar = !_ocultar),
                ),
              ),
            ),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      activeColor: const Color(0xFF38BDF8),
                      checkColor: const Color(0xFF0F0529),
                      value: _recordarme,
                      onChanged: _cargando
                          ? null
                          : (value) =>
                                setState(() => _recordarme = value ?? false),
                    ),
                    const Text(
                      'Recordarme',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                // El círculo de la transición nace del propio enlace.
                Builder(
                  builder: (botonContext) => TextButton(
                    onPressed: _cargando
                        ? null
                        : () {
                            final caja =
                                botonContext.findRenderObject()! as RenderBox;
                            final origen = caja.localToGlobal(
                              caja.size.center(Offset.zero),
                            );
                            Navigator.push(
                              context,
                              RecoverScreen.ruta(origen: origen),
                            );
                          },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF7DD3FC),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      '¿Olvidaste tu contraseña?',
                      style: TextStyle(fontFamily: 'Outfit', fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _cargando ? null : _enviar,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8),
                foregroundColor: const Color(0xFF0F0529),
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
                        color: Color(0xFF0F0529),
                      ),
                    )
                  : const Text('Iniciar sesión'),
            ),
            const SizedBox(height: 14),
            Text(
              '¿Problemas para ingresar? Contacta a coordinación.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11.5,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EtiquetaPortal extends StatelessWidget {
  const _EtiquetaPortal();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.verified_user_outlined, size: 15, color: Color(0xFF7DD3FC)),
        SizedBox(width: 8),
        Text(
          'Acceso institucional UTB',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFFE2E8F0),
          ),
        ),
      ],
    ),
  );
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensaje,
              style: const TextStyle(color: AppColors.navy, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
