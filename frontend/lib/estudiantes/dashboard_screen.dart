import 'package:flutter/material.dart';

import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/widgets/async_view.dart';
import 'package:frontend/core/widgets/metric_card.dart';
import 'package:frontend/core/widgets/page_list.dart';
import 'package:frontend/core/widgets/responsive_grid.dart';
import 'package:frontend/requisitos/models.dart';
import 'package:frontend/requisitos/requisitos_service.dart';
import 'estudiantes_service.dart';
import 'models.dart';
import 'widgets/dashboard_components.dart';

class _DatosInicio {
  const _DatosInicio(this.estudiante, this.resumen, this.requisitos);

  final Estudiante estudiante;
  final ResumenRequisitos resumen;
  final List<Requisito> requisitos;
}

/// Pantalla principal del estudiante con sus datos académicos.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.estudiantes,
    required this.requisitos,
    required this.codigoEstudiantil,
  });

  final EstudiantesService estudiantes;
  final RequisitosService requisitos;
  final String codigoEstudiantil;

  Future<_DatosInicio> _cargar() async {
    final resultados = await Future.wait<Object>([
      estudiantes.obtener(codigoEstudiantil),
      requisitos.obtenerResumen(codigoEstudiantil),
      requisitos.obtenerRequisitos(codigoEstudiantil),
    ]);
    return _DatosInicio(
      resultados[0] as Estudiante,
      resultados[1] as ResumenRequisitos,
      resultados[2] as List<Requisito>,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AsyncView<_DatosInicio>(
      load: _cargar,
      builder: (context, datos) {
        final resumen = datos.resumen;
        return PageList(
          children: [
            DashboardWelcomeCard(
              estudiante: datos.estudiante,
              resumen: resumen,
            ),
            if (resumen.pendientes > 0) ...[
              const SizedBox(height: 18),
              _AvisoPendientes(pendientes: resumen.pendientes),
            ],
            const SizedBox(height: 18),
            ResponsiveGrid(
              minTileWidth: 220,
              spacing: 12,
              children: [
                MetricCard(
                  title: 'Requisitos de grado',
                  value: '${resumen.total}',
                  caption: 'En tu plan académico',
                  icon: Icons.fact_check_outlined,
                  color: AppColors.navy,
                  background: AppColors.surfaceLow,
                ),
                MetricCard(
                  title: 'Cumplidos',
                  value: '${resumen.cumplidos}',
                  caption: 'Validados',
                  icon: Icons.check_circle_outline,
                  color: AppColors.successText,
                  background: AppColors.successBg,
                ),
                MetricCard(
                  title: 'En proceso',
                  value: '${resumen.enProceso}',
                  caption: 'Actualmente en curso',
                  icon: Icons.timelapse_outlined,
                  color: AppColors.info,
                  background: AppColors.infoBg,
                ),
                MetricCard(
                  title: 'Pendientes',
                  value: '${resumen.pendientes}',
                  caption: 'Requieren seguimiento',
                  icon: Icons.error_outline,
                  color: AppColors.warningText,
                  background: AppColors.warningBg,
                ),
              ],
            ),
            const SizedBox(height: 22),
            DashboardRequirementsPanel(requisitos: datos.requisitos),
          ],
        );
      },
    );
  }
}

class _AvisoPendientes extends StatelessWidget {
  const _AvisoPendientes({required this.pendientes});

  final int pendientes;

  @override
  Widget build(BuildContext context) {
    final texto = pendientes == 1
        ? 'Tienes 1 requisito pendiente. Revísalo con tiempo para no retrasar tu grado.'
        : 'Tienes $pendientes requisitos pendientes. Revísalos con tiempo para no retrasar tu grado.';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warningText,
            size: 26,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Atención requerida',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.warningText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  texto,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.warningText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
