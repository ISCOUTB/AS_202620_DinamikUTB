import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/administracion/service/admin_service.dart';
import 'package:frontend/administracion/widgets/admin_common_widgets.dart';
import 'package:frontend/administracion/widgets/students_detail_dialog.dart';
import 'package:frontend/administracion/widgets/student_edit_dialog.dart';
import 'package:frontend/administracion/widgets/student_registration_dialog.dart';

class AdminStudentsScreen extends StatefulWidget {
  const AdminStudentsScreen({
    super.key,
    required this.service,
    required this.initialSearch,
  });

  final AdminService service;
  final String initialSearch;

  @override
  State<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State<AdminStudentsScreen> {
  late final _search = TextEditingController(text: widget.initialSearch);
  late Future<List<AdminStudent>> _future;
  int _offset = 0;
  String? _program;
  int? _semester;
  bool? _active;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<List<AdminStudent>> _load() => widget.service.estudiantes(
    buscar: _search.text,
    programa: _program,
    semestre: _semester,
    activo: _active,
    offset: _offset,
  );

  void _refresh() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) => AdminPageFrame(
    title: 'Estudiantes',
    subtitle:
        'Consulta perfiles académicos, estado de cuenta y avance de requisitos.',
    trailing: FilledButton.icon(
      // Llamada directa al diálogo de registro conservado
      onPressed: _registerStudent,
      icon: const Icon(Icons.person_add_alt_1_outlined, size: 16),
      label: const Text('Registrar estudiante'),
    ),
    children: [
      // Buscador
      Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) {
                  _offset = 0;
                  _refresh();
                },
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre, correo o código...',
                  hintStyle: const TextStyle(fontSize: 12),
                  prefixIcon: const Icon(Icons.search, size: 18),
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: 'Buscar',
            onPressed: () {
              _offset = 0;
              _refresh();
            },
            icon: const Icon(Icons.search, size: 18),
          ),
        ],
      ),
      const SizedBox(height: 12),

      // Filtros compactos, con bordes redondeados y adaptables a pantallas pequeñas
      LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;
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
                        for (final program in snapshot.data!)
                          DropdownMenuItem(
                            value: program.nombre,
                            child: Text(program.nombre),
                          ),
                    ],
                    onChanged: (value) {
                      _program = value == null || value.isEmpty ? null : value;
                      _offset = 0;
                      _refresh();
                    },
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
                    const DropdownMenuItem(
                      value: '',
                      child: Text('Todos los semestres'),
                    ),
                    for (var semester = 1; semester <= 12; semester++)
                      DropdownMenuItem(
                        value: '$semester',
                        child: Text('Semestre $semester'),
                      ),
                  ],
                  onChanged: (value) {
                    _semester = int.tryParse(value ?? '');
                    _offset = 0;
                    _refresh();
                  },
                ),
              ),
              SizedBox(
                width: itemWidth,
                height: 40,
                child: DropdownButtonFormField<String>(
                  initialValue: _active == null
                      ? ''
                      : _active!
                      ? 'true'
                      : 'false',
                  borderRadius: BorderRadius.circular(12),
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                  decoration: adminFilterInputDecoration('Estado'),
                  items: const [
                    DropdownMenuItem(
                      value: '',
                      child: Text('Todos los estados'),
                    ),
                    DropdownMenuItem(value: 'true', child: Text('Activo')),
                    DropdownMenuItem(value: 'false', child: Text('Inactivo')),
                  ],
                  onChanged: (value) {
                    _active = value == null || value.isEmpty
                        ? null
                        : value == 'true';
                    _offset = 0;
                    _refresh();
                  },
                ),
              ),
            ],
          );
        },
      ),
      const SizedBox(height: 14),

      // Lista de estudiantes
      FutureBuilder<List<AdminStudent>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return AdminLoadError(
              message: adminErrorMessage(snapshot.error),
              retry: _refresh,
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
          final students = snapshot.data!;
          if (students.isEmpty) {
            return const AdminEmptyState(
              icon: Icons.groups_2_outlined,
              title: 'No se encontraron estudiantes',
              detail: 'Ajusta los filtros o registra un nuevo estudiante.',
            );
          }

          return Column(
            children: [
              for (final student in students)
                Card(
                  elevation: 0.5,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    onTap: () => _showStudentDetails(student),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.infoBg,
                      child: Text(
                        student.nombre.isEmpty
                            ? '?'
                            : student.nombre[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.bold,
                        ),
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
                      '${student.codigo} · ${student.email}\n${student.programa} · Semestre ${student.semestre ?? '—'}',
                      style: const TextStyle(fontSize: 10, height: 1.5),
                    ),
                    isThreeLine: true,
                    trailing: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        AdminStatusTag(student.activo ? 'Activo' : 'Inactivo'),
                        IconButton(
                          tooltip: 'Editar estudiante',
                          onPressed: () => _editStudent(student),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              // Paginación
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _offset == 0
                          ? null
                          : () {
                              _offset = (_offset - 50).clamp(0, 1 << 30);
                              _refresh();
                            },
                      child: const Text('Anterior'),
                    ),
                    Text(
                      'Desde ${_offset + 1}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    TextButton(
                      onPressed: students.length < 50
                          ? null
                          : () {
                              _offset += 50;
                              _refresh();
                            },
                      child: const Text('Siguiente'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ],
  );

  Future<void> _registerStudent() async {
    final created = await StudentRegistrationDialog.show(
      context,
      widget.service,
    );
    if (created == true) _refresh();
  }

  Future<void> _editStudent(AdminStudent student) async {
    final updated = await StudentEditDialog.show(
      context,
      service: widget.service,
      student: student,
    );
    if (updated == true) _refresh();
  }

  void _showStudentDetails(AdminStudent student) {
    showDialog<void>(
      context: context,
      builder: (context) => StudentDetailDialog(
        student: student,
        onEdit: () => _editStudent(student),
      ),
    );
  }
}
