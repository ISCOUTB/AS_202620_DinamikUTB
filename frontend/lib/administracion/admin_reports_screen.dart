import 'package:flutter/material.dart';
import 'package:frontend/core/download_file.dart';
import 'package:frontend/administracion/service/admin_service.dart';
import 'widgets/admin_chart_panel.dart';
import 'widgets/admin_common_widgets.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key, required this.service});
  final AdminService service;

  @override
  State<AdminReportsScreen> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsScreen> {
  late Future<Map<String, dynamic>> _future = widget.service.resumen();
  bool _exporting = false;

  Future<void> _exportar() async {
    setState(() => _exporting = true);
    try {
      final bytes = await widget.service.exportarEstudiantes();
      if (!mounted) return;
      final downloaded = downloadFile(
        bytes,
        'dinamikutb-estudiantes.csv',
        'text/csv;charset=utf-8',
      );
      showAdminSnackBar(
        context,
        downloaded
            ? 'El reporte CSV se descargó exitosamente.'
            : 'La descarga solo está disponible desde el navegador web.',
      );
    } catch (error) {
      if (mounted) showAdminSnackBar(context, adminErrorMessage(error));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return AdminLoadError(
          message: adminErrorMessage(snapshot.error),
          retry: () => setState(() => _future = widget.service.resumen()),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

      final data = snapshot.data!;
      return AdminPageFrame(
        title: 'Reportes y estadísticas',
        subtitle: 'Indicadores calculados a partir de los registros actuales.',
        children: [
          AdminChartPanel(
            title: 'Estudiantes por programa',
            values: parseAdminIntMap(data['por_programa']),
            empty: 'Sin registros.',
          ),
          const SizedBox(height: 12),
          AdminChartPanel(
            title: 'Distribución por semestre',
            values: parseAdminIntMap(data['por_semestre']),
            empty: 'Sin semestres registrados.',
          ),
          const SizedBox(height: 12),

          // MEJORA: Formateo automático de estados [Cumplido, En Proceso, Pendiente]
          AdminChartPanel(
            title: 'Estado de requisitos',
            values: parseAdminIntMap(data['estados_requisitos']),
            empty: 'Sin requisitos registrados.',
            isStatusChart: true,
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              FilledButton.icon(
                onPressed: _exporting ? null : _exportar,
                icon: _exporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.download_outlined, size: 16),
                label: const Text('Descargar reporte CSV'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0.5,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Total: ${data['total_estudiantes']} estudiantes · Cumplimiento: ${data['porcentaje_cumplimiento']}% · Próximos a grado: ${data['estudiantes_proximos_grado']}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
