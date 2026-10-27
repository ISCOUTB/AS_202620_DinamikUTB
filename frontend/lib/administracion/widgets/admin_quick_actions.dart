import 'package:flutter/material.dart';

enum QuickActionMode {
  card, // Modo tarjeta para pantalla amplia
  horizontal, // Modo barra superior para pantallas compactas
}

/// Widget de accesos rápidos que se adapta según el tamaño de la pantalla.
class AdminQuickActions extends StatelessWidget {
  const AdminQuickActions({
    super.key,
    required this.mode,
    required this.onRegisterStudent,
    required this.onCreateProgram,
    required this.onManageRequirements,
    required this.onViewProgress,
  });

  final QuickActionMode mode;
  final VoidCallback onRegisterStudent;
  final VoidCallback onCreateProgram;
  final VoidCallback onManageRequirements;
  final VoidCallback onViewProgress;

  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        Icons.person_add_alt_1_outlined,
        'Registrar estudiante',
        onRegisterStudent,
      ),
      (Icons.add_business_outlined, 'Crear programa', onCreateProgram),
      (
        Icons.playlist_add_check_rounded,
        'Gestionar requisitos',
        onManageRequirements,
      ),
      (Icons.query_stats_rounded, 'Ver seguimiento', onViewProgress),
    ];

    if (mode == QuickActionMode.horizontal) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final action in actions)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  avatar: Icon(action.$1, size: 16),
                  label: Text(action.$2, style: const TextStyle(fontSize: 11)),
                  onPressed: action.$3,
                  visualDensity: const VisualDensity(
                    horizontal: -1,
                    vertical: -1,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // Modo Card estándar para escritorio
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Accesos rápidos',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final action in actions)
                  OutlinedButton.icon(
                    onPressed: action.$3,
                    icon: Icon(action.$1, size: 16),
                    label: Text(
                      action.$2,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
