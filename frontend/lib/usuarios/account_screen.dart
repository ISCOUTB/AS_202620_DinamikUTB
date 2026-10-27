import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/network/api_exception.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/validators.dart';
import 'auth_controller.dart';

enum AccountPage { recuperar, restablecer, perfil, actualizarContrasena }

class AccountScreen extends StatefulWidget {
  const AccountScreen({
    super.key,
    required this.page,
    this.email = '',
    this.codigo = '',
    this.programa = '',
    this.nombre = '',
    this.semestre,
    this.token = '',
    this.onCompleted,
  });

  final AccountPage page;
  final String email;
  final String codigo;
  final String programa;
  final String nombre;
  final int? semestre;
  final String token;
  final VoidCallback? onCompleted;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  late final _correo = TextEditingController(text: widget.email);
  final _codigo = TextEditingController();
  final _contrasena = TextEditingController();
  final _confirmar = TextEditingController();
  final _actual = TextEditingController();
  final _token = TextEditingController();
  String? _programa;
  int? _semestre;
  bool _ocultar = true;
  bool _cargando = false;
  bool _cargandoProgramas = false;
  List<String> _programas = [];
  String? _errorProgramas;
  String? _errorFormulario;
  String? _estado;

  @override
  void initState() {
    super.initState();
    _nombre.text = widget.nombre;
    _codigo.text = widget.codigo;
    _token.text = widget.token;
    _programa = widget.programa.isEmpty ? null : widget.programa;
    _semestre = widget.semestre;
    _contrasena.addListener(_actualizarFortaleza);
    if (widget.page == AccountPage.perfil) {
      _cargarProgramas();
    }
  }

  void _actualizarFortaleza() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _codigo.dispose();
    _contrasena.dispose();
    _confirmar.dispose();
    _actual.dispose();
    _token.dispose();
    super.dispose();
  }

  Future<void> _cargarProgramas() async {
    setState(() {
      _cargandoProgramas = true;
      _errorProgramas = null;
    });
    try {
      final data =
          await context.read<ApiClient>().get('/programas') as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _programas = [
          for (final item in data)
            (item as Map<String, dynamic>)['nombre'] as String,
        ];
        if (!_programas.contains(_programa)) _programa = null;
        _cargandoProgramas = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorProgramas = error.message;
        _cargandoProgramas = false;
      });
    }
  }

  String get _titulo => switch (widget.page) {
    AccountPage.recuperar => 'Recupera tu contraseña',
    AccountPage.restablecer => 'Define una nueva contraseña',
    AccountPage.perfil => 'Tu información académica',
    AccountPage.actualizarContrasena => 'Actualiza tu contraseña',
  };

  String get _descripcion => switch (widget.page) {
    AccountPage.recuperar =>
      'Te guiaremos para verificar tu identidad de forma segura.',
    AccountPage.restablecer =>
      'Crea una contraseña segura para proteger tu cuenta.',
    AccountPage.perfil =>
      'Consulta o prepara la actualización de tus datos personales y académicos.',
    AccountPage.actualizarContrasena =>
      'Por seguridad, confirma tu contraseña actual antes de elegir otra.',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.navy,
        title: const Text(
          'DinamikUTB',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth > 900 ? 820 : 540,
              ),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(constraints.maxWidth > 600 ? 30 : 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Encabezado(
                          page: widget.page,
                          title: _titulo,
                          description: _descripcion,
                        ),
                        const SizedBox(height: 18),
                        if (widget.page == AccountPage.recuperar)
                          const _RecoveryMethodNotice(),
                        if (widget.page == AccountPage.recuperar)
                          const SizedBox(height: 16),
                        if (_errorProgramas != null) ...[
                          _EstadoError(
                            mensaje: _errorProgramas!,
                            onRetry: _cargarProgramas,
                          ),
                          const SizedBox(height: 14),
                        ],
                        if (_errorFormulario != null) ...[
                          _EstadoError(mensaje: _errorFormulario!),
                          const SizedBox(height: 14),
                        ],
                        if (_estado != null) ...[
                          _EstadoExito(mensaje: _estado!),
                          const SizedBox(height: 16),
                        ],
                        _campos(),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _cargando ? null : _procesar,
                            child: _cargando
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(_boton),
                          ),
                        ),
                        if (widget.page == AccountPage.restablecer &&
                            _estado != null &&
                            widget.onCompleted != null) ...[
                          const SizedBox(height: 8),
                          Center(
                            child: TextButton(
                              onPressed: widget.onCompleted,
                              child: const Text('Ir al inicio de sesión'),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton.icon(
                            onPressed: () => Navigator.maybePop(context),
                            icon: const Icon(Icons.arrow_back, size: 17),
                            label: const Text('Volver'),
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

  String get _boton => switch (widget.page) {
    AccountPage.recuperar => 'Enviar instrucciones',
    AccountPage.restablecer => 'Guardar nueva contraseña',
    AccountPage.perfil => 'Guardar cambios',
    AccountPage.actualizarContrasena => 'Actualizar contraseña',
  };

  Widget _campos() {
    switch (widget.page) {
      case AccountPage.recuperar:
        return _field(
          _correo,
          'Correo institucional',
          hint: 'nombre@dinamikutb.dev',
          icon: Icons.mail_outline,
          keyboard: TextInputType.emailAddress,
          validator: Validators.correoInstitucional,
        );
      case AccountPage.restablecer:
        return Column(
          children: [
            _field(
              _token,
              'Código seguro de recuperación',
              hint: 'Pega el código recibido del administrador',
              icon: Icons.verified_user_outlined,
              validator: (value) => value == null || value.trim().length < 32
                  ? 'El código de recuperación no es válido.'
                  : null,
            ),
            const SizedBox(height: 13),
            _campoContrasena('Nueva contraseña'),
            const SizedBox(height: 13),
            _campoConfirmacion('Confirmar nueva contraseña'),
            const SizedBox(height: 12),
            _fortaleza(),
          ],
        );
      case AccountPage.perfil:
        return Column(
          children: [
            _field(
              _nombre,
              'Nombres completos',
              hint: 'Nombres y apellidos',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 13),
            _field(
              _correo,
              'Correo electrónico',
              icon: Icons.mail_outline,
              enabled: false,
            ),
            const SizedBox(height: 13),
            _seleccionPrograma(),
            const SizedBox(height: 13),
            _seleccionSemestre(),
            const SizedBox(height: 13),
            _field(
              _codigo,
              'Código estudiantil',
              icon: Icons.badge_outlined,
              enabled: false,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => AccountScreen(
                    page: AccountPage.actualizarContrasena,
                    email: widget.email,
                  ),
                ),
              ),
              icon: const Icon(Icons.lock_outline),
              label: const Text('Gestionar contraseña'),
            ),
          ],
        );
      case AccountPage.actualizarContrasena:
        return Column(
          children: [
            _field(
              _actual,
              'Contraseña actual',
              icon: Icons.lock_outline,
              obscure: _ocultar,
              suffix: _togglePassword,
            ),
            const SizedBox(height: 13),
            _campoContrasena('Nueva contraseña'),
            const SizedBox(height: 13),
            _campoConfirmacion('Confirmar nueva contraseña'),
            const SizedBox(height: 12),
            _fortaleza(),
          ],
        );
    }
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    required IconData icon,
    TextInputType? keyboard,
    bool enabled = true,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: controller,
    enabled: enabled,
    keyboardType: keyboard,
    obscureText: obscure,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
    ),
    validator:
        validator ??
        (value) => (value == null || value.trim().isEmpty)
            ? 'Completa este campo.'
            : null,
  );

  Widget _campoContrasena(String label) => _field(
    _contrasena,
    label,
    icon: Icons.lock_outline,
    obscure: _ocultar,
    suffix: _togglePassword,
    validator: (value) => value == null || value.length < 12
        ? 'Usa al menos 12 caracteres.'
        : null,
  );

  Widget _campoConfirmacion(String label) => _field(
    _confirmar,
    label,
    icon: Icons.verified_user_outlined,
    obscure: _ocultar,
    suffix: _togglePassword,
    validator: (value) =>
        value != _contrasena.text ? 'Las contraseñas no coinciden.' : null,
  );

  Widget get _togglePassword => IconButton(
    tooltip: _ocultar ? 'Mostrar contraseña' : 'Ocultar contraseña',
    onPressed: () => setState(() => _ocultar = !_ocultar),
    icon: Icon(
      _ocultar ? Icons.visibility_outlined : Icons.visibility_off_outlined,
    ),
  );

  Widget _seleccionPrograma() => DropdownButtonFormField<String>(
    initialValue: _programa,
    decoration: const InputDecoration(
      labelText: 'Carrera o programa académico',
      prefixIcon: Icon(Icons.school_outlined),
    ),
    items: [
      for (final programa in _programas)
        DropdownMenuItem(value: programa, child: Text(programa)),
    ],
    onChanged: _cargandoProgramas
        ? null
        : (value) => setState(() => _programa = value),
    validator: (value) =>
        value == null ? 'Selecciona un programa activo.' : null,
  );

  Widget _seleccionSemestre() => DropdownButtonFormField<int>(
    initialValue: _semestre,
    decoration: const InputDecoration(
      labelText: 'Semestre actual',
      prefixIcon: Icon(Icons.calendar_today_outlined),
    ),
    items: [
      for (var i = 1; i <= 12; i++)
        DropdownMenuItem(
          value: i,
          child: Text('$i${i == 1 ? 'er' : '°'} semestre'),
        ),
    ],
    onChanged: (value) => setState(() => _semestre = value),
    validator: (value) => value == null ? 'Selecciona tu semestre.' : null,
  );

  Widget _fortaleza() {
    final valor = _contrasena.text;
    final puntos = [
      valor.length >= 12,
      RegExp(r'[A-Z]').hasMatch(valor) && RegExp(r'[a-z]').hasMatch(valor),
      RegExp(r'\d').hasMatch(valor),
      RegExp(r'[^A-Za-z0-9]').hasMatch(valor),
    ].where((ok) => ok).length;
    final color = puntos < 2
        ? AppColors.danger
        : puntos < 4
        ? AppColors.warningText
        : AppColors.successText;
    final nivel = puntos < 2
        ? 'Débil'
        : puntos < 4
        ? 'Aceptable'
        : 'Fuerte';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Seguridad de la contraseña',
                style: TextStyle(fontSize: 11),
              ),
            ),
            Text(
              nivel,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: puntos / 4,
          color: color,
          backgroundColor: AppColors.surfaceLow,
        ),
        const SizedBox(height: 5),
        const Text(
          'Combina 12 caracteres o más, mayúsculas, números y símbolos.',
          style: TextStyle(fontSize: 10, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Future<void> _procesar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _errorFormulario = null;
      _estado = null;
    });
    final auth = context.read<AuthController>();
    try {
      switch (widget.page) {
        case AccountPage.recuperar:
          await auth.solicitarRecuperacion(_correo.text.trim());
          if (mounted) {
            setState(
              () => _estado =
                  'Si el correo pertenece a una cuenta activa, recibirás instrucciones.',
            );
          }
        case AccountPage.restablecer:
          await auth.restablecerPassword(_token.text.trim(), _contrasena.text);
          if (mounted) {
            setState(
              () => _estado =
                  'Contraseña restablecida. Ya puedes iniciar sesión.',
            );
            widget.onCompleted?.call();
          }
        case AccountPage.perfil:
          await auth.actualizarPerfil(
            nombre: _nombre.text.trim(),
            programa: _programa!,
            semestre: _semestre!,
          );
          if (mounted) setState(() => _estado = 'Perfil actualizado.');
        case AccountPage.actualizarContrasena:
          await auth.cambiarPassword(
            actual: _actual.text,
            nueva: _contrasena.text,
          );
          if (mounted) {
            setState(
              () => _estado = 'Contraseña actualizada. Inicia sesión de nuevo.',
            );
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _errorFormulario = error.message);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({
    required this.page,
    required this.title,
    required this.description,
  });
  final AccountPage page;
  final String title, description;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.infoBg,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(
          page == AccountPage.recuperar || page == AccountPage.restablecer
              ? Icons.lock_reset_rounded
              : Icons.person_outline,
          color: AppColors.cyan,
        ),
      ),
      const SizedBox(width: 13),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    ],
  );
}

class _RecoveryMethodNotice extends StatelessWidget {
  const _RecoveryMethodNotice();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.warningBg,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.warning.withValues(alpha: 0.45)),
    ),
    child: const Row(
      children: [
        Icon(Icons.info_outline, color: AppColors.warningText, size: 18),
        SizedBox(width: 9),
        Expanded(
          child: Text(
            'Este entorno no tiene correo de recuperación configurado. Solicita a administración que verifique tu identidad y emita un enlace temporal.',
            style: TextStyle(fontSize: 11, color: AppColors.navy),
          ),
        ),
      ],
    ),
  );
}

class _EstadoExito extends StatelessWidget {
  const _EstadoExito({required this.mensaje});
  final String mensaje;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.successBg,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.check_circle_outline,
          color: AppColors.successText,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(mensaje, style: const TextStyle(fontSize: 11))),
      ],
    ),
  );
}

class _EstadoError extends StatelessWidget {
  const _EstadoError({required this.mensaje, this.onRetry});
  final String mensaje;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.dangerBg,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(mensaje, style: const TextStyle(fontSize: 11))),
        if (onRetry != null)
          IconButton(
            tooltip: 'Reintentar',
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
          ),
      ],
    ),
  );
}
