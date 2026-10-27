import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/requisitos/requisitos_service.dart';
import 'package:frontend/administracion/service/admin_service.dart';
import 'admin_common_widgets.dart';
import 'admin_metric_card.dart';

class StudentDetailDialog extends StatelessWidget {
  const StudentDetailDialog({
    super.key,
    required this.student,
    required this.onEdit,
  });

  final AdminStudent student;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final service = context.read<RequisitosService>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera del estudiante
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.infoBg,
                    child: Text(
                      student.nombre.isEmpty
                          ? '?'
                          : student.nombre[0].toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.nombre,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${student.codigo} · ${student.email}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        Text(
                          '${student.programa} · Semestre ${student.semestre ?? '—'}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AdminStatusTag(student.activo ? 'Activo' : 'Inactivo'),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 10),

              // Carga de avances y requisitos
              Expanded(
                child: FutureBuilder(
                  future: service.obtenerResumen(student.codigo),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'No se pudo obtener el progreso del estudiante.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.danger,
                          ),
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final summary = snapshot.data!;
                    final percent = summary.porcentajeAvance;
                    final pendientes = summary.pendientes;
                    final isAtRisk = percent < 50;
                    final isNearGraduation =
                        (student.semestre ?? 0) >= 8 && pendientes > 0;

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Estado y Avance Académico',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Widgets de Avance trasladados desde el Dashboard principal
                          Row(
                            children: [
                              Expanded(
                                child: AdminMetricCard(
                                  title: 'Cumplimiento general',
                                  value: '${percent.toStringAsFixed(0)}%',
                                  icon: Icons.track_changes_outlined,
                                  color: AppColors.successText,
                                  subtitle: 'Avance curricular',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: AdminMetricCard(
                                  title: 'Requisitos pendientes',
                                  value: '$pendientes',
                                  icon: Icons.pending_actions_outlined,
                                  color: AppColors.warningText,
                                  subtitle: 'Por completar',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Barra de progreso y desglose
                          LinearProgressIndicator(
                            value: (percent / 100).clamp(0.0, 1.0),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(8),
                            backgroundColor: AppColors.surfaceLow,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isAtRisk ? AppColors.warningText : AppColors.cyan,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${summary.cumplidos} cumplidos · ${summary.enProceso} en revisión · $pendientes pendientes',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Bloque de Advertencias
                          const Text(
                            'Diagnóstico y Advertencias',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (isAtRisk)
                            _WarningBanner(
                              icon: Icons.warning_amber_rounded,
                              color: AppColors.danger,
                              bgColor: AppColors.warningBg,
                              title: 'Riesgo de rezago académico',
                              message:
                                  'El estudiante posee un avance inferior al 50%. Requiere acompañamiento para el cumplimiento de requisitos.',
                            )
                          else if (isNearGraduation)
                            _WarningBanner(
                              icon: Icons.info_outline_rounded,
                              color: AppColors.warningText,
                              bgColor: AppColors.warningBg,
                              title: 'Atención: Próximo a egreso',
                              message:
                                  'Cursa semestres finales y aún mantiene $pendientes requisito(s) pendiente(s) de grado.',
                            )
                          else
                            _WarningBanner(
                              icon: Icons.check_circle_outline_rounded,
                              color: AppColors.successText,
                              bgColor: AppColors.successBg,
                              title: 'Avance normal',
                              message:
                                  'El estudiante marcha sin alertas críticas de requisitos académicos.',
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),

              // Botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onEdit();
                    },
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Editar estudiante'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final Color bgColor;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(message, style: const TextStyle(fontSize: 11, height: 1.3)),
            ],
          ),
        ),
      ],
    ),
  );
}
