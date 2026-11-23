import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/requisitos/requisitos_service.dart';
import 'package:frontend/administracion/service/admin_service.dart';
import 'widgets/admin_common_widgets.dart';

class AdminProgressScreen extends StatefulWidget {
  const AdminProgressScreen({super.key, required this.service});
  final AdminService service;

  @override
  State<AdminProgressScreen> createState() => _AdminProgressPageState();
}

class _AdminProgressPageState extends State<AdminProgressScreen> {
  late Future<List<AdminStudent>> _future = widget.service.estudiantes();
  String? _program;
  int? _semester;
  String _level = 'all';

  void _loadStudents() {
    _future = widget.service.estudiantes(
      programa: _program,
      semestre: _semester,
    );
  }

  @override
  Widget build(BuildContext context) => AdminPageFrame(
    title: 'Seguimiento académico',
    subtitle:
        'Identifica el avance individual y los requisitos que necesitan atención.',
    children: [
      // Filtros adaptativos y compactos
      LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 620;
          final itemWidth = isNarrow ? (constraints.maxWidth - 10) / 2 : 200.0;

          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FutureBuilder<List<AdminProgram>>(
                future: widget.service.programas(),
                builder: (context, snapshot) => SizedBox(
                  width: isNarrow ? constraints.maxWidth : 240,
                  height: 40,
                  child: DropdownButtonFormField<String>(
                    initialValue: _program ?? '',
                    borderRadius: BorderRadius.circular(12),
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                    decoration: adminFilterInputDecoration('Programa'),
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('Todos los programas'),
                      ),
                      if (snapshot.hasData)
                        for (final p in snapshot.data!)
                          DropdownMenuItem(
                            value: p.nombre,
                            child: Text(p.nombre),
                          ),
                    ],
                    onChanged: (value) => setState(() {
                      _program = value == null || value.isEmpty ? null : value;
                      _loadStudents();
                    }),
                  ),
                ),
              ),
              SizedBox(
                width: itemWidth,
                height: 40,
                child: DropdownButtonFormField<String>(
                  initialValue: _semester?.toString() ?? '',
                  borderRadius: BorderRadius.circular(12),
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                  decoration: adminFilterInputDecoration('Semestre'),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('Todos')),
                    for (var semester = 1; semester <= 12; semester++)
                      DropdownMenuItem(
                        value: '$semester',
                        child: Text('Semestre $semester'),
                      ),
                  ],
                  onChanged: (value) => setState(() {
                    _semester = int.tryParse(value ?? '');
                    _loadStudents();
                  }),
                ),
              ),
              SizedBox(
                width: isNarrow ? constraints.maxWidth : 210,
                height: 40,
                child: DropdownButtonFormField<String>(
                  initialValue: _level,
                  borderRadius: BorderRadius.circular(12),
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                  decoration: adminFilterInputDecoration('Nivel de avance'),
                  items: const [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text('Todos los niveles'),
                    ),
                    DropdownMenuItem(
                      value: 'attention',
                      child: Text('Atención (<50%)'),
                    ),
                    DropdownMenuItem(
                      value: 'progress',
                      child: Text('En progreso (50–79%)'),
                    ),
                    DropdownMenuItem(
                      value: 'near',
                      child: Text('Próximo (≥80%)'),
                    ),
                  ],
                  onChanged: (value) => setState(() => _level = value ?? 'all'),
                ),
              ),
            ],
          );
        },
      ),
      const SizedBox(height: 14),

      // Lista de estudiantes con avance
      FutureBuilder<List<AdminStudent>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return AdminLoadError(
              message: adminErrorMessage(snapshot.error),
              retry: () => setState(
                () => _future = widget.service.estudiantes(programa: _program),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (snapshot.data!.isEmpty) {
            return const AdminEmptyState(
              icon: Icons.trending_up,
              title: 'Sin estudiantes para mostrar',
              detail: 'Registra estudiantes para iniciar el seguimiento.',
            );
          }
          return Column(
            children: [
              for (final student in snapshot.data!)
                _StudentProgressCard(
                  student: student,
                  level: _level,
                  onRetry: () => setState(() {}),
                ),
            ],
          );
        },
      ),
    ],
  );
}

class _StudentProgressCard extends StatelessWidget {
  const _StudentProgressCard({
    required this.student,
    required this.level,
    required this.onRetry,
  });

  final AdminStudent student;
  final String level;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final service = context.read<RequisitosService>();

    return FutureBuilder(
      future: service.obtenerResumen(student.codigo),
      builder: (context, snapshot) {
        final summary = snapshot.data;
        if (snapshot.hasError) {
          return AdminLoadError(
            message: adminErrorMessage(snapshot.error),
            retry: onRetry,
          );
        }
        if (summary == null) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: LinearProgressIndicator(),
          );
        }

        final percent = summary.porcentajeAvance;
        final matchesLevel = switch (level) {
          'attention' => percent < 50,
          'progress' => percent >= 50 && percent < 80,
          'near' => percent >= 80,
          _ => true,
        };
        if (!matchesLevel) return const SizedBox.shrink();

        return Card(
          elevation: 0.5,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.nombre,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${student.programa} · Semestre ${student.semestre ?? '—'} · ${student.codigo}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${percent.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: AppColors.cyan,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: percent / 100,
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(8),
                  backgroundColor: AppColors.surfaceLow,
                ),
                const SizedBox(height: 8),
                Text(
                  '${summary.cumplidos} cumplidos · ${summary.enProceso} en revisión · ${summary.pendientes} pendientes',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
