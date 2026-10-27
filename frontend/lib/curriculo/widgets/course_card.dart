import 'package:flutter/material.dart';

import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/curriculo/models.dart';

class CourseCard extends StatelessWidget {
  const CourseCard({super.key, required this.curso});

  final CursoCurricular curso;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                curso.codigo,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.cyan,
                  fontWeight: FontWeight.w700,
                ),
              ),
              _CourseTag(
                label:
                    '${curso.creditos} ${curso.creditos == 1 ? 'crédito' : 'créditos'}',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            curso.nombre,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (curso.prerequisitos.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Prerrequisitos',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final codigo in curso.prerequisitos)
                  _CourseTag(label: codigo),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}

class _CourseTag extends StatelessWidget {
  const _CourseTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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
