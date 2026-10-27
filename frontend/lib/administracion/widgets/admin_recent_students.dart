import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/administracion/service/admin_service.dart';
import 'admin_common_widgets.dart';

/// Tabla / Lista responsiva de estudiantes recientes.
class AdminRecentStudents extends StatefulWidget {
  const AdminRecentStudents({
    super.key,
    required this.service,
    required this.onViewAll,
  });

  final AdminService service;
  final VoidCallback onViewAll;

  @override
  State<AdminRecentStudents> createState() => _AdminRecentStudentsState();
}

class _AdminRecentStudentsState extends State<AdminRecentStudents> {
  late Future<List<AdminStudent>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.estudiantes(limite: 5);
  }

  void _retry() {
    setState(() => _future = widget.service.estudiantes(limite: 5));
  }

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0.5,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: AppColors.border),
    ),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estudiantes recientes',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Últimos registros académicos en la plataforma.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: widget.onViewAll,
                child: const Text('Ver directorio'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<AdminStudent>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return AdminLoadError(
                  message: adminErrorMessage(snapshot.error),
                  retry: _retry,
                );
              }
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final students = snapshot.data!;
              if (students.isEmpty) {
                return const AdminEmptyState(
                  icon: Icons.groups_2_outlined,
                  title: 'Aún no hay estudiantes registrados',
                  detail: 'Los nuevos registros aparecerán en esta sección.',
                );
              }
              return LayoutBuilder(
                builder: (context, constraints) {
                  // Vista móvil / estrecha
                  if (constraints.maxWidth < 650) {
                    return Column(
                      children: [
                        for (final student in students)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: AppColors.infoBg,
                              child: Text(
                                student.nombre.isEmpty
                                    ? '?'
                                    : student.nombre[0].toUpperCase(),
                                style: const TextStyle(color: AppColors.navy),
                              ),
                            ),
                            title: Text(
                              student.nombre,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              '${student.codigo} · ${student.programa}\nSemestre ${student.semestre ?? '—'}',
                              style: const TextStyle(fontSize: 10, height: 1.5),
                            ),
                            isThreeLine: true,
                            trailing: AdminStatusTag(
                              student.activo ? 'Activo' : 'Inactivo',
                            ),
                          ),
                      ],
                    );
                  }

                  // Vista amplia con DataTable scrollable horizontalmente para evitar colapso
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                      ),
                      child: DataTable(
                        columnSpacing: 24,
                        columns: const [
                          DataColumn(label: Text('Estudiante')),
                          DataColumn(label: Text('Código')),
                          DataColumn(label: Text('Programa')),
                          DataColumn(label: Text('Semestre')),
                          DataColumn(label: Text('Estado')),
                        ],
                        rows: [
                          for (final student in students)
                            DataRow(
                              cells: [
                                DataCell(
                                  SizedBox(
                                    width: 170,
                                    child: Text(
                                      student.nombre,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                DataCell(Text(student.codigo)),
                                DataCell(
                                  SizedBox(
                                    width: 190,
                                    child: Text(
                                      student.programa,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                DataCell(Text('${student.semestre ?? '—'}')),
                                DataCell(
                                  AdminStatusTag(
                                    student.activo ? 'Activo' : 'Inactivo',
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    ),
  );
}
