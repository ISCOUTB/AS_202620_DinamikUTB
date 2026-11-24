import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/widgets/page_list.dart';
import 'account_screen.dart';
import 'auth_controller.dart';
import 'models.dart';

/// Perfil con fondo oscuro iluminado en las esquinas, la mascota confundida a
/// la derecha y toda la información disponible de la cuenta debajo.
class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key, required this.usuario});

  static const _etiquetaCerrarSesion = 'Cerrar sesión';

  final Usuario usuario;

  Future<void> _confirmarSalida(BuildContext context) async {
    final auth = context.read<AuthController>();
    final salir = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(_etiquetaCerrarSesion),
        content: const Text('¿Quieres cerrar tu sesión en este dispositivo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(_etiquetaCerrarSesion),
          ),
        ],
      ),
    );
    if (salir ?? false) await auth.cerrarSesion();
  }

  void _abrirCuenta(BuildContext context, AccountPage page) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AccountScreen(
          page: page,
          email: usuario.email,
          codigo: usuario.codigoEstudiantil ?? '',
          nombre: usuario.nombre ?? '',
          programa: usuario.programa ?? '',
          semestre: usuario.semestre,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombre = usuario.nombre?.trim();
    final nombreVisible = nombre == null || nombre.isEmpty
        ? usuario.email
        : nombre;
    final iniciales = _iniciales(nombreVisible);

    return Stack(
      children: [
        const Positioned.fill(child: CustomPaint(painter: _FondoPerfil())),
        PageList(
          maxWidth: 980,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final cabecera = _EncabezadoPerfil(
                  nombre: nombreVisible,
                  iniciales: iniciales,
                  usuario: usuario,
                );
                final mascota = const _MascotaConfundida();
                if (constraints.maxWidth < 640) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      cabecera,
                      const SizedBox(height: 16),
                      Center(child: mascota),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: cabecera),
                    const SizedBox(width: 24),
                    SizedBox(width: 250, child: mascota),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            _PanelOscuro(
              titulo: 'Información del estudiante',
              subtitulo: 'Todo lo que sabemos de tu cuenta institucional.',
              accion: _BotonAccion(
                texto: 'Editar datos',
                icono: Icons.edit_outlined,
                relleno: false,
                onPressed: () => _abrirCuenta(context, AccountPage.perfil),
              ),
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columnas = constraints.maxWidth >= 640 ? 2 : 1;
                    const hueco = 12.0;
                    final ancho =
                        (constraints.maxWidth - hueco * (columnas - 1)) /
                        columnas;
                    return Wrap(
                      spacing: hueco,
                      runSpacing: hueco,
                      children: [
                        _DatoPerfil(
                          ancho: ancho,
                          etiqueta: 'Nombre completo',
                          valor: nombreVisible,
                          icono: Icons.person_outline_rounded,
                        ),
                        _DatoPerfil(
                          ancho: ancho,
                          etiqueta: 'Correo institucional',
                          valor: usuario.email,
                          icono: Icons.mail_outline_rounded,
                        ),
                        _DatoPerfil(
                          ancho: ancho,
                          etiqueta: 'Dominio del correo',
                          valor: _dominio(usuario.email),
                          icono: Icons.alternate_email_rounded,
                        ),
                        _DatoPerfil(
                          ancho: ancho,
                          etiqueta: 'Código estudiantil',
                          valor: usuario.codigoEstudiantil ?? 'No asociado',
                          icono: Icons.badge_outlined,
                        ),
                        _DatoPerfil(
                          ancho: ancho,
                          etiqueta: 'Programa académico',
                          valor: usuario.programa ?? 'No asignado',
                          icono: Icons.school_outlined,
                        ),
                        _DatoPerfil(
                          ancho: ancho,
                          etiqueta: 'Semestre actual',
                          valor: usuario.semestre == null
                              ? 'No registrado'
                              : '${usuario.semestre} de 12',
                          icono: Icons.calendar_month_outlined,
                        ),
                        _DatoPerfil(
                          ancho: ancho,
                          etiqueta: 'Rol en la plataforma',
                          valor: usuario.rol.etiqueta,
                          icono: Icons.verified_user_outlined,
                        ),
                        _DatoPerfil(
                          ancho: ancho,
                          etiqueta: 'Estado de la cuenta',
                          valor: 'Activo actualmente',
                          icono: Icons.check_circle_outline_rounded,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _PanelOscuro(
              titulo: 'Seguridad y acceso',
              subtitulo: 'Mantén tu contraseña segura y controla tu sesión.',
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _abrirCuenta(
                        context,
                        AccountPage.actualizarContrasena,
                      ),
                      icon: const Icon(Icons.lock_outline_rounded),
                      label: const Text('Actualizar contraseña'),
                    ),
                    _BotonAccion(
                      texto: _etiquetaCerrarSesion,
                      icono: Icons.logout_rounded,
                      relleno: true,
                      onPressed: () => _confirmarSalida(context),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  String _iniciales(String nombre) {
    final partes = nombre
        .trim()
        .split(RegExp(r'\s+'))
        .where((parte) => parte.isNotEmpty)
        .take(2);
    return partes.map((parte) => parte[0].toUpperCase()).join();
  }

  String _dominio(String email) {
    final corte = email.indexOf('@');
    if (corte < 0 || corte == email.length - 1) return 'Institucional';
    return email.substring(corte);
  }
}

// ---------------------------------------------------------------------------
// Fondo oscuro con luces en las esquinas
// ---------------------------------------------------------------------------

class _FondoPerfil extends CustomPainter {
  const _FondoPerfil();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF05050B), Color(0xFF0A0913), Color(0xFF06060D)],
        ).createShader(rect),
    );

    // Luces en las esquinas: rosa, morado, azul y magenta.
    _luz(canvas, size, const Alignment(-1, -1), const Color(0xFFF472B6), 0.34);
    _luz(canvas, size, const Alignment(1, -1), const Color(0xFFA855F7), 0.32);
    _luz(canvas, size, const Alignment(-1, 1), const Color(0xFF38BDF8), 0.22);
    _luz(canvas, size, const Alignment(1, 1), const Color(0xFFDB2777), 0.28);
    // Bruma tenue central para que el negro no se vea plano.
    _luz(canvas, size, Alignment.center, const Color(0xFF7C3AED), 0.12);
  }

  void _luz(
    Canvas canvas,
    Size size,
    Alignment alineacion,
    Color color,
    double intensidad,
  ) {
    final centro = Offset(
      size.width * (alineacion.x + 1) / 2,
      size.height * (alineacion.y + 1) / 2,
    );
    final radio = size.shortestSide * 0.75 + size.longestSide * 0.18;
    canvas.drawCircle(
      centro,
      radio,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: intensidad),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: centro, radius: radio)),
    );
  }

  @override
  bool shouldRepaint(covariant _FondoPerfil antiguo) => false;
}

// ---------------------------------------------------------------------------
// Cabecera con la mascota a la derecha
// ---------------------------------------------------------------------------

class _EncabezadoPerfil extends StatelessWidget {
  const _EncabezadoPerfil({
    required this.nombre,
    required this.iniciales,
    required this.usuario,
  });

  final String nombre;
  final String iniciales;
  final Usuario usuario;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.09),
          Colors.white.withValues(alpha: 0.04),
        ],
      ),
      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.45),
          blurRadius: 26,
          offset: const Offset(0, 12),
        ),
      ],
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final detalles = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              nombre,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              usuario.programa ?? usuario.rol.etiqueta,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Etiqueta(
                  texto: usuario.rol == Rol.estudiante
                      ? 'Estudiante de pregrado'
                      : '${usuario.rol.etiqueta} con acceso de gestión',
                  icono: Icons.school_outlined,
                  tono: const Color(0xFFC4B5FD),
                ),
                const _Etiqueta(
                  texto: 'Activo actualmente',
                  icono: Icons.verified_outlined,
                  tono: Color(0xFF34D399),
                ),
                if (usuario.codigoEstudiantil != null)
                  _Etiqueta(
                    texto: 'Código ${usuario.codigoEstudiantil}',
                    icono: Icons.badge_outlined,
                    tono: const Color(0xFF38BDF8),
                  ),
                if (usuario.semestre != null)
                  _Etiqueta(
                    texto: 'Semestre ${usuario.semestre}',
                    icono: Icons.calendar_month_outlined,
                    tono: const Color(0xFFF472B6),
                  ),
                _Etiqueta(
                  texto: usuario.email.contains('@')
                      ? usuario.email.substring(usuario.email.indexOf('@'))
                      : 'Correo institucional',
                  icono: Icons.alternate_email_rounded,
                  tono: const Color(0xFFFCD34D),
                ),
              ],
            ),
          ],
        );

        final avatar = Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFF472B6), Color(0xFFA855F7), Color(0xFF38BDF8)],
            ),
          ),
          child: CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFF101828),
            child: Text(
              iniciales.isEmpty ? '?' : iniciales,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        );

        if (constraints.maxWidth < 460) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [avatar, const SizedBox(height: 16), detalles],
          );
        }
        return Row(
          children: [
            avatar,
            const SizedBox(width: 18),
            Expanded(child: detalles),
          ],
        );
      },
    ),
  );
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({
    required this.texto,
    required this.icono,
    required this.tono,
  });

  final String texto;
  final IconData icono;
  final Color tono;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: tono.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: tono.withValues(alpha: 0.45)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 14, color: tono),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            texto,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _MascotaConfundida extends StatelessWidget {
  const _MascotaConfundida();

  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    children: [
      Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: RadialGradient(
              center: const Alignment(0, 0.05),
              radius: 0.75,
              colors: [const Color(0x8CA855F7), const Color(0x00A855F7)],
            ),
          ),
        ),
      ),
      Image.asset(
        'assets/images/mascota_confundida.png',
        fit: BoxFit.contain,
        // En las pruebas de widget el PNG no llega a decodificar; se deja un
        // hueco del mismo tamaño para no mover el resto del diseño.
        errorBuilder: (context, error, stackTrace) => const SizedBox(
          width: double.infinity,
          height: 240,
          child: Center(
            child: Text(
              '?',
              style: TextStyle(
                color: Color(0xFFC4B5FD),
                fontSize: 96,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Paneles y datos sobre fondo oscuro
// ---------------------------------------------------------------------------

class _PanelOscuro extends StatelessWidget {
  const _PanelOscuro({
    required this.titulo,
    required this.subtitulo,
    required this.children,
    this.accion,
  });

  final String titulo;
  final String subtitulo;
  final Widget? accion;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF15151F), Color(0xFF0C0C15)],
      ),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _EncabezadoSeccion(
          titulo: titulo,
          subtitulo: subtitulo,
          accion: accion,
        ),
        const SizedBox(height: 18),
        ...children,
      ],
    ),
  );
}

class _EncabezadoSeccion extends StatelessWidget {
  const _EncabezadoSeccion({
    required this.titulo,
    required this.subtitulo,
    this.accion,
  });

  final String titulo;
  final String subtitulo;
  final Widget? accion;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final bloque = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitulo,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF94A3B8)),
          ),
        ],
      );
      if (accion == null) return bloque;
      if (constraints.maxWidth < 520) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [bloque, const SizedBox(height: 12), accion!],
        );
      }
      return Row(
        children: [
          Expanded(child: bloque),
          const SizedBox(width: 12),
          accion!,
        ],
      );
    },
  );
}

class _DatoPerfil extends StatelessWidget {
  const _DatoPerfil({
    required this.ancho,
    required this.etiqueta,
    required this.valor,
    required this.icono,
  });

  final double ancho;
  final String etiqueta;
  final String valor;
  final IconData icono;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: ancho,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(icono, color: AppColors.cyanLight, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etiqueta.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  valor,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _BotonAccion extends StatelessWidget {
  const _BotonAccion({
    required this.texto,
    required this.icono,
    required this.relleno,
    required this.onPressed,
  });

  final String texto;
  final IconData icono;
  final bool relleno;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(icono, size: 18);
    if (relleno) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon,
        label: Text(texto),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon,
      label: Text(texto),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.cyanLight,
        side: BorderSide(color: AppColors.cyanLight.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
