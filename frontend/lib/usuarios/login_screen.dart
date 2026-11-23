import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/network/api_exception.dart';
import 'package:frontend/core/responsive/breakpoints.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/validators.dart';
import 'account_screen.dart';
import 'auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _ocultar = true;
  bool _cargando = false;
  bool _recordarme = false;
  String? _error;

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final ancho = constraints.maxWidth >= Breakpoints.expanded;
          final formulario = _formulario(context);
          if (!ancho) {
            return SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _Marca(oscura: false),
                        const SizedBox(height: 24),
                        formulario,
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
          return Row(
            children: [
              const Expanded(flex: 5, child: _PanelMarca()),
              Expanded(
                flex: 4,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(48),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: formulario,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _formulario(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Bienvenido a DinamikUTB',
                  style: tema.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gestiona tu progreso académico y alcanza tus metas',
                  style: tema.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 20),
                if (_error != null) ...[
                  _Aviso(mensaje: _error!),
                  const SizedBox(height: 16),
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
                const SizedBox(height: 16),
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
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          value: _recordarme,
                          onChanged: _cargando
                              ? null
                              : (value) => setState(
                                  () => _recordarme = value ?? false,
                                ),
                        ),
                        const Text(
                          'Recordarme',
                          style: TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: _cargando
                          ? null
                          : () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const AccountScreen(
                                  page: AccountPage.recuperar,
                                ),
                              ),
                            ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: _cargando ? null : _enviar,
                  child: _cargando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Iniciar sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(mensaje)),
        ],
      ),
    );
  }
}

class _Marca extends StatelessWidget {
  const _Marca({required this.oscura});

  /// Usa texto claro cuando el fondo es oscuro.
  final bool oscura;

  @override
  Widget build(BuildContext context) {
    final color = oscura ? Colors.white : AppColors.navy;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 64,
          width: 64,
          decoration: BoxDecoration(
            color: oscura ? Colors.white12 : AppColors.navy,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.school_rounded,
            color: AppColors.gold,
            size: 36,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'DinamikUTB',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PanelMarca extends StatelessWidget {
  const _PanelMarca();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    const puntos = [
      (Icons.flag_outlined, 'Conoce qué requisitos de grado ya cumpliste'),
      (Icons.timelapse_outlined, 'Detecta a tiempo lo que te falta'),
      (Icons.lock_outline, 'Tu información académica, solo para ti'),
    ];
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.navy, Color(0xFF123B6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(56),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Marca(oscura: true),
          const SizedBox(height: 32),
          Text(
            'Tu camino a la graduación, siempre a la vista.',
            style: tema.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          for (final (icono, texto) in puntos)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(icono, color: AppColors.cyanLight),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      texto,
                      style: tema.bodyLarge?.copyWith(color: Colors.white70),
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
