import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/widgets/page_list.dart';
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(_etiquetaCerrarSesion),
          ),
        ],
      ),
    );
    if (salir ?? false) await auth.cerrarSesion();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final inicial = usuario.email.isEmpty ? '?' : usuario.email[0].toUpperCase();
    return PageList(
      maxWidth: 640,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.navy,
                  child: Text(inicial, style: tema.headlineMedium?.copyWith(color: Colors.white)),
                ),
                const SizedBox(height: 16),
                Text(usuario.email, style: tema.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Chip(label: Text(usuario.rol.etiqueta)),
                if (usuario.codigoEstudiantil != null) ...[
                  const SizedBox(height: 8),
                  Text('Código: ${usuario.codigoEstudiantil}',
                      style: tema.bodyMedium?.copyWith(color: AppColors.textMuted)),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => _confirmarSalida(context),
          icon: const Icon(Icons.logout),
          label: const Text(_etiquetaCerrarSesion),
        ),
      ],
    );
  }
}
