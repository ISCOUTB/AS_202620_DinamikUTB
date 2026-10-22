import 'package:flutter/material.dart';

import 'models.dart';
import 'requirement_status_chip.dart';

class RequisitoCard extends StatelessWidget {
  const RequisitoCard({super.key, required this.requisito, this.pie});

  final Requisito requisito;

  /// Contenido opcional que aparece debajo del estado.
  final Widget? pie;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(requisito.nombre,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            RequirementStatusChip(estado: requisito.estado),
            if (pie != null) ...[const SizedBox(height: 12), pie!],
          ],
        ),
      ),
    );
  }
}
