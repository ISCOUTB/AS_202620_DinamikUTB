import 'package:flutter/material.dart';

import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/widgets/async_view.dart';
import 'package:frontend/core/widgets/page_list.dart';
import 'package:frontend/core/widgets/responsive_grid.dart';
import 'models.dart';
import 'requisito_card.dart';
import 'requisitos_service.dart';

/// Consulta los requisitos del estudiante y permite filtrarlos por estado.
class RequisitosScreen extends StatefulWidget {
  const RequisitosScreen({
    super.key,
    required this.service,
    required this.estudianteId,
  });

  final RequisitosService service;
  final String estudianteId;

  @override
  State<RequisitosScreen> createState() => _RequisitosScreenState();
}

class _RequisitosScreenState extends State<RequisitosScreen> {
  EstadoRequisito? _filtro;

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<Requisito>>(
      load: () => widget.service.obtenerRequisitos(widget.estudianteId),
      builder: (context, requisitos) {
        if (requisitos.isEmpty) {
          return const PageList(children: [
            Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(child: Text('No tienes requisitos registrados.')),
            ),
          ]);
        }
        final visibles = _filtro == null
            ? requisitos
            : requisitos.where((r) => r.estado == _filtro).toList();
        return PageList(children: [
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
          const SizedBox(height: 16),
          if (visibles.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: Center(
                child: Text('No hay requisitos con este estado.',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
            )
          else
            ResponsiveGrid(
              minTileWidth: 320,
              children: [for (final r in visibles) RequisitoCard(requisito: r)],
            ),
        ]);
      },
    );
  }
}
