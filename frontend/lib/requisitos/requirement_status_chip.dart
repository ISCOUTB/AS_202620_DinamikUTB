import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'models.dart';

class RequirementStatusChip extends StatelessWidget {
  const RequirementStatusChip({super.key, required this.estado});

  final EstadoRequisito estado;

  @override
  Widget build(BuildContext context) {
    final (color, fondo, icono) = switch (estado) {
      EstadoRequisito.cumplido => (AppColors.successText, AppColors.successBg, Icons.check_circle_outline),
      EstadoRequisito.enProceso => (AppColors.info, AppColors.infoBg, Icons.timelapse_outlined),
      EstadoRequisito.pendiente => (AppColors.warningText, AppColors.warningBg, Icons.error_outline),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 16, color: color),
          const SizedBox(width: 6),
          Text(estado.etiqueta,
              style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12.5)),
        ],
      ),
    );
  }
}
