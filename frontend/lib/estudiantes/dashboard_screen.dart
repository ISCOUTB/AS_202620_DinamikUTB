import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/widgets/async_view.dart';
import '../core/widgets/page_list.dart';
import '../core/widgets/responsive_grid.dart';
import '../requisitos/models.dart';
import '../requisitos/requisito_card.dart';
import '../requisitos/requisitos_service.dart';
import 'estudiantes_service.dart';
import 'models.dart';

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
        final tema = Theme.of(context).textTheme;
        final resumen = datos.resumen;
        final atencion = datos.requisitos
            .where((r) => r.estado != EstadoRequisito.cumplido)
            .toList();
        return PageList(children: [
          Text('Hola, ${datos.estudiante.nombre}',
              style: tema.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(datos.estudiante.programa,
              style: tema.bodyLarge?.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 20),
          ResponsiveGrid(minTileWidth: 230, children: [
            _TarjetaAvance(resumen: resumen),
            _Indicador(
              titulo: 'Cumplidos',
              valor: resumen.cumplidos,
              icono: Icons.check_circle_outline,
              color: AppColors.successText,
              fondo: AppColors.successBg,
            ),
            _Indicador(
              titulo: 'En proceso',
              valor: resumen.enProceso,
              icono: Icons.timelapse_outlined,
              color: AppColors.info,
              fondo: AppColors.infoBg,
            ),
            _Indicador(
              titulo: 'Pendientes',
              valor: resumen.pendientes,
              icono: Icons.error_outline,
              color: AppColors.warningText,
              fondo: AppColors.warningBg,
            ),
          ]),
          if (resumen.pendientes > 0) ...[
            const SizedBox(height: 20),
            _AvisoPendientes(pendientes: resumen.pendientes),
          ],
          const SizedBox(height: 28),
          Text('Requisitos que requieren atención',
              style: tema.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (atencion.isEmpty)
            const Text('Todos tus requisitos registrados están cumplidos.')
          else
            ResponsiveGrid(
              minTileWidth: 320,
              children: [for (final r in atencion) RequisitoCard(requisito: r)],
            ),
        ]);
      },
    );
  }
}

class _TarjetaAvance extends StatelessWidget {
  const _TarjetaAvance({required this.resumen});

  final ResumenRequisitos resumen;

  @override
  Widget build(BuildContext context) {
    final porcentaje = resumen.porcentajeAvance;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Semantics(
              label: 'Avance de requisitos: ${porcentaje.toStringAsFixed(0)} por ciento',
              child: SizedBox(
                height: 80,
                width: 80,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: porcentaje / 100,
                      strokeWidth: 9,
                      backgroundColor: AppColors.surfaceLow,
                    ),
                    Center(
                      child: Text('${porcentaje.toStringAsFixed(0)}%',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Avance', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('${resumen.cumplidos} de ${resumen.total} requisitos',
                      style: const TextStyle(color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Indicador extends StatelessWidget {
  const _Indicador({
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.color,
    required this.fondo,
  });

  final String titulo;
  final int valor;
  final IconData icono;
  final Color color;
  final Color fondo;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(10)),
              child: Icon(icono, color: color),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$valor',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                Text(titulo, style: const TextStyle(color: AppColors.textMuted)),
              ],
            ),
          ],
        ),
      ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warningText),
          const SizedBox(width: 12),
          Expanded(child: Text(texto)),
        ],
      ),
    );
  }
}
