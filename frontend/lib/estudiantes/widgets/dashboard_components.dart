import 'package:flutter/material.dart';

import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/requisitos/models.dart';
import 'package:frontend/requisitos/requirement_status_chip.dart';
import 'package:frontend/estudiantes/models.dart';

class DashboardWelcomeCard extends StatelessWidget {
  const DashboardWelcomeCard({
    super.key,
    required this.estudiante,
    required this.resumen,
  });

  final Estudiante estudiante;
  final ResumenRequisitos resumen;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final profile = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    size: 16,
                    color: AppColors.cyan,
                  ),
                  Text(
                    'INFORMACIÓN ACADÉMICA',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.cyan,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  _ProfileTag(label: 'Código ${estudiante.codigoEstudiantil}'),
                  if (estudiante.semestre != null)
                    _ProfileTag(label: 'Semestre ${estudiante.semestre}'),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Hola, ${estudiante.nombre}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                estudiante.programa,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textMuted),
              ),
            ],
          );
          final progress = _ProgressBadge(resumen: resumen);
          return constraints.maxWidth >= 680
              ? Row(
                  children: [
                    Expanded(child: profile),
                    const SizedBox(width: 24),
                    progress,
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    profile,
                    const Divider(height: 32),
                    Center(child: progress),
                  ],
                );
        },
      ),
    ),
  );
}

class DashboardRequirementsPanel extends StatefulWidget {
  const DashboardRequirementsPanel({super.key, required this.requisitos});

  final List<Requisito> requisitos;

  @override
  State<DashboardRequirementsPanel> createState() =>
      _DashboardRequirementsPanelState();
}

class _DashboardRequirementsPanelState
    extends State<DashboardRequirementsPanel> {
  EstadoRequisito? _filtro;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Matriz de requisitos de grado',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Consulta el estado registrado para cada requisito de grado.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Todos'),
                selected: _filtro == null,
                onSelected: (_) => setState(() => _filtro = null),
              ),
              for (final estado in EstadoRequisito.values)
                ChoiceChip(
                  label: Text(switch (estado) {
                    EstadoRequisito.cumplido => 'Cumplidos',
                    EstadoRequisito.enProceso => 'En curso',
                    EstadoRequisito.pendiente => 'Pendientes',
                  }),
                  selected: _filtro == estado,
                  onSelected: (_) => setState(() => _filtro = estado),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (widget.requisitos.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text('Aún no tienes requisitos de grado registrados.'),
            )
          else
            Builder(
              builder: (context) {
                final visibles = widget.requisitos
                    .where(
                      (requisito) =>
                          _filtro == null || requisito.estado == _filtro,
                    )
                    .toList();
                if (visibles.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Text('No hay requisitos con este estado.'),
                  );
                }
                return Column(
                  children: [
                    for (var index = 0; index < visibles.length; index++) ...[
                      if (index > 0) const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final titulo = Text(
                              visibles[index].nombre,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            );
                            final estado = RequirementStatusChip(
                              estado: visibles[index].estado,
                            );
                            return constraints.maxWidth < 430
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      titulo,
                                      const SizedBox(height: 8),
                                      estado,
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Expanded(child: titulo),
                                      const SizedBox(width: 12),
                                      estado,
                                    ],
                                  );
                          },
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
        ],
      ),
    ),
  );
}

class _ProgressBadge extends StatelessWidget {
  const _ProgressBadge({required this.resumen});

  final ResumenRequisitos resumen;

  @override
  Widget build(BuildContext context) {
    final porcentaje = resumen.porcentajeAvance.clamp(0, 100);
    final indicator = Semantics(
      label: 'Avance de requisitos: ${porcentaje.toStringAsFixed(0)}%',
      child: SizedBox(
        width: 76,
        height: 76,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: porcentaje / 100,
              strokeWidth: 8,
              backgroundColor: AppColors.surfaceLow,
              color: AppColors.cyan,
            ),
            Center(
              child: Text(
                '${porcentaje.toStringAsFixed(0)}%',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
    Widget details({required bool centered}) => Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          'AVANCE GENERAL',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          '${resumen.cumplidos} de ${resumen.total}',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(
          'requisitos cumplidos',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth < 340
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                indicator,
                const SizedBox(height: 10),
                details(centered: true),
              ],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                indicator,
                const SizedBox(width: 14),
                details(centered: false),
              ],
            ),
    );
  }
}

class _ProfileTag extends StatelessWidget {
  const _ProfileTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.surfaceLow,
      borderRadius: BorderRadius.circular(7),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppColors.navy,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
