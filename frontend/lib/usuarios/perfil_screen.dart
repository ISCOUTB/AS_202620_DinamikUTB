import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/widgets/page_list.dart';
import 'account_screen.dart';
import 'auth_controller.dart';
import 'models.dart';

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

    return PageList(
      maxWidth: 900,
      children: [
        _ProfileHeader(
          nombre: nombreVisible,
          iniciales: iniciales,
          rol: usuario.rol.etiqueta,
          programa: usuario.programa,
          codigo: usuario.codigoEstudiantil,
          semestre: usuario.semestre,
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  title: 'Datos personales y académicos',
                  subtitle: 'Información asociada a tu cuenta institucional.',
                  action: OutlinedButton.icon(
                    onPressed: () => _abrirCuenta(context, AccountPage.perfil),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Editar datos'),
                  ),
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 620 ? 2 : 1;
                    final gap = 12.0;
                    final width =
                        (constraints.maxWidth - gap * (columns - 1)) / columns;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        _ProfileField(
                          width: width,
                          label: 'Correo institucional',
                          value: usuario.email,
                          icon: Icons.mail_outline_rounded,
                        ),
                        _ProfileField(
                          width: width,
                          label: 'Código estudiantil',
                          value: usuario.codigoEstudiantil ?? 'No asociado',
                          icon: Icons.badge_outlined,
                        ),
                        _ProfileField(
                          width: width,
                          label: 'Programa académico',
                          value: usuario.programa ?? 'No asignado',
                          icon: Icons.school_outlined,
                        ),
                        _ProfileField(
                          width: width,
                          label: 'Semestre',
                          value: usuario.semestre == null
                              ? 'No registrado'
                              : '${usuario.semestre}',
                          icon: Icons.calendar_month_outlined,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader(
                  title: 'Seguridad y acceso',
                  subtitle: 'Mantén tu contraseña segura y controla tu sesión.',
                ),
                const SizedBox(height: 16),
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
                    OutlinedButton.icon(
                      onPressed: () => _confirmarSalida(context),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text(_etiquetaCerrarSesion),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.nombre,
    required this.iniciales,
    required this.rol,
    required this.programa,
    required this.codigo,
    required this.semestre,
  });

  final String nombre;
  final String iniciales;
  final String rol;
  final String? programa;
  final String? codigo;
  final int? semestre;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppColors.navy,
      borderRadius: BorderRadius.circular(18),
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
            const SizedBox(height: 5),
            Text(
              programa ?? rol,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _HeaderTag(label: rol, icon: Icons.verified_user_outlined),
                if (codigo != null)
                  _HeaderTag(
                    label: 'Código $codigo',
                    icon: Icons.badge_outlined,
                  ),
                if (semestre != null)
                  _HeaderTag(
                    label: 'Semestre $semestre',
                    icon: Icons.calendar_month_outlined,
                  ),
              ],
            ),
          ],
        );
        final avatar = CircleAvatar(
          radius: 34,
          backgroundColor: Colors.white,
          child: Text(
            iniciales.isEmpty ? '?' : iniciales,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w800,
            ),
          ),
        );
        return constraints.maxWidth < 540
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [avatar, const SizedBox(height: 16), detalles],
              )
            : Row(
                children: [
                  avatar,
                  const SizedBox(width: 20),
                  Expanded(child: detalles),
                ],
              );
      },
    ),
  );
}

class _HeaderTag extends StatelessWidget {
  const _HeaderTag({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.cyanLight),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final titleBlock = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
        ],
      );
      if (action == null) return titleBlock;
      if (constraints.maxWidth < 520) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [titleBlock, const SizedBox(height: 12), action!],
        );
      }
      return Row(
        children: [
          Expanded(child: titleBlock),
          const SizedBox(width: 12),
          action!,
        ],
      );
    },
  );
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
  });

  final double width;
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.cyan, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.navy,
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
