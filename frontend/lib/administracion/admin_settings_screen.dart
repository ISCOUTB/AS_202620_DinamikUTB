import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/usuarios/account_screen.dart';
import 'widgets/admin_common_widgets.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key, required this.email});
  final String email;

  @override
  Widget build(BuildContext context) => AdminPageFrame(
    title: 'Configuración',
    subtitle: 'Preferencias de cuenta y seguridad del perfil.',
    children: [
      Card(
        elevation: 0.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cuenta actual',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: AppColors.infoBg,
                  child: Icon(Icons.person_outline, color: AppColors.cyan),
                ),
                title: const Text(
                  'Administrador institucional',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  email,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => AccountScreen(
                      page: AccountPage.actualizarContrasena,
                      email: email,
                    ),
                  ),
                ),
                icon: const Icon(Icons.lock_outline, size: 16),
                label: const Text('Actualizar contraseña'),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
