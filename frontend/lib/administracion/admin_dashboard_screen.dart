import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'admin_panel_screen.dart';
import 'package:frontend/administracion/service/admin_service.dart';
import 'widgets/admin_chart_panel.dart';
import 'widgets/admin_common_widgets.dart';
import 'widgets/admin_metric_card.dart';
import 'widgets/admin_quick_actions.dart';
import 'widgets/admin_recent_students.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({
    super.key,
    required this.service,
    required this.onNavigate,
  });

  final AdminService service;
  final ValueChanged<AdminSection> onNavigate;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isReduced = screenWidth < 850;

    return FutureBuilder<Map<String, dynamic>>(
      future: service.resumen(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return AdminLoadError(
            message: adminErrorMessage(snapshot.error),
            retry: () {},
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!;

        // Únicamente 3 métricas en el dashboard principal
        final mainStats = [
          (
            'Estudiantes registrados',
            '${data['total_estudiantes']}',
            Icons.groups_2_outlined,
            AppColors.cyan,
          ),
          (
            'Programas académicos',
            '${data['total_programas']}',
            Icons.school_outlined,
            AppColors.cyan,
          ),
          (
            'Próximos a grado',
            '${data['estudiantes_proximos_grado']}',
            Icons.workspace_premium_outlined,
            AppColors.successText,
          ),
        ];

        return AdminPageFrame(
          title: 'Bienvenido al panel de administración',
          subtitle:
              'Gestiona la información académica y supervisa el progreso institucional.',
          // Si disminuye la pantalla, los accesos rápidos se reubican como barra horizontal justo abajo del subtítulo
          headerBottomWidget: isReduced
              ? AdminQuickActions(
                  mode: QuickActionMode.horizontal,
                  onRegisterStudent: () => onNavigate(AdminSection.estudiantes),
                  onCreateProgram: () => onNavigate(AdminSection.programas),
                  onManageRequirements: () =>
                      onNavigate(AdminSection.requisitos),
                  onViewProgress: () => onNavigate(AdminSection.seguimiento),
                )
              : null,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.infoBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Periodo actual: 2026',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.navy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          children: [
            // Grid responsivo de las 3 métricas que no ocupa toda la pantalla de forma rígida
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final cols = width > 850
                    ? 3
                    : width > 520
                    ? 2
                    : 1;
                final cardWidth = (width - ((cols - 1) * 12)) / cols;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final stat in mainStats)
                      SizedBox(
                        width: cardWidth,
                        child: AdminMetricCard(
                          title: stat.$1,
                          value: stat.$2,
                          icon: stat.$3,
                          color: stat.$4,
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Tabla de estudiantes recientes
            AdminRecentStudents(
              service: service,
              onViewAll: () => onNavigate(AdminSection.estudiantes),
            ),
            const SizedBox(height: 16),

            // Gráficas de distribución
            LayoutBuilder(
              builder: (context, constraints) {
                final programData = parseAdminIntMap(data['por_programa']);
                final semesterData = parseAdminIntMap(data['por_semestre']);
                final states = parseAdminIntMap(data['estados_requisitos']);
                final wide = constraints.maxWidth >= 900;

                final distribution = AdminChartPanel(
                  title: 'Estudiantes por programa',
                  values: programData,
                  empty: 'No hay estudiantes registrados por programa.',
                );
                final semesters = AdminChartPanel(
                  title: 'Estudiantes por semestre',
                  values: semesterData,
                  empty: 'Los registros aún no tienen semestre informado.',
                );
                final status = AdminChartPanel(
                  title: 'Estado de requisitos',
                  values: states,
                  empty: 'No hay requisitos de grado registrados.',
                  isStatusChart: true,
                );

                return wide
                    ? Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 2, child: distribution),
                              const SizedBox(width: 12),
                              Expanded(child: semesters),
                            ],
                          ),
                          const SizedBox(height: 12),
                          status,
                        ],
                      )
                    : Column(
                        children: [
                          distribution,
                          const SizedBox(height: 12),
                          semesters,
                          const SizedBox(height: 12),
                          status,
                        ],
                      );
              },
            ),

            // Si la pantalla es grande, dejamos el panel tradicional de accesos rápidos al final
            if (!isReduced) ...[
              const SizedBox(height: 16),
              AdminQuickActions(
                mode: QuickActionMode.card,
                onRegisterStudent: () => onNavigate(AdminSection.estudiantes),
                onCreateProgram: () => onNavigate(AdminSection.programas),
                onManageRequirements: () => onNavigate(AdminSection.requisitos),
                onViewProgress: () => onNavigate(AdminSection.seguimiento),
              ),
            ],
          ],
        );
      },
    );
  }
}
