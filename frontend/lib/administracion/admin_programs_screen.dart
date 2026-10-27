import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/administracion/service/admin_service.dart';
import 'widgets/admin_common_widgets.dart';

class AdminProgramsScreen extends StatefulWidget {
  const AdminProgramsScreen({super.key, required this.service});
  final AdminService service;

  @override
  State<AdminProgramsScreen> createState() => _AdminProgramsPageState();
}

class _AdminProgramsPageState extends State<AdminProgramsScreen> {
  late Future<List<AdminProgram>> _future = widget.service.programas(
    administrar: true,
  );

  void _refresh() =>
      setState(() => _future = widget.service.programas(administrar: true));

  @override
  Widget build(BuildContext context) => AdminPageFrame(
    title: 'Programas académicos',
    subtitle:
        'Mantén el catálogo institucional y la duración curricular al día.',
    trailing: FilledButton.icon(
      onPressed: () => _edit(context),
      icon: const Icon(Icons.add, size: 16),
      label: const Text('Crear programa'),
    ),
    children: [
      FutureBuilder<List<AdminProgram>>(
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
          if (snapshot.data!.isEmpty) {
            return const AdminEmptyState(
              icon: Icons.school_outlined,
              title: 'El catálogo está vacío',
              detail:
                  'Crea un programa para habilitar el registro de estudiantes.',
            );
          }
          return Column(
            children: [
              for (final program in snapshot.data!)
                Card(
                  elevation: 0.5,
                  margin: const EdgeInsets.only(bottom: 9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.infoBg,
                      child: Icon(
                        Icons.school_outlined,
                        color: AppColors.cyan,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      program.nombre,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      '${program.codigo} · ${program.facultad}\n${program.duracionSemestres} semestres · ${program.estudiantes} estudiantes',
                      style: const TextStyle(fontSize: 10, height: 1.6),
                    ),
                    isThreeLine: true,
                    trailing: Wrap(
                      children: [
                        AdminStatusTag(program.activo ? 'Activo' : 'Inactivo'),
                        IconButton(
                          tooltip: 'Editar programa',
                          onPressed: () => _edit(context, program),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ],
  );

  Future<void> _edit(BuildContext context, [AdminProgram? program]) async {
    final key = GlobalKey<FormState>();
    final code = TextEditingController(text: program?.codigo ?? '');
    final name = TextEditingController(text: program?.nombre ?? '');
    final faculty = TextEditingController(text: program?.facultad ?? '');
    final duration = TextEditingController(
      text: '${program?.duracionSemestres ?? 10}',
    );
    var active = program?.activo ?? true;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(program == null ? 'Crear programa' : 'Editar programa'),
          content: SizedBox(
            width: 440,
            child: Form(
              key: key,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AdminFormField(
                      controller: name,
                      label: 'Nombre del programa',
                    ),
                    AdminFormField(
                      controller: code,
                      label: 'Código del programa',
                    ),
                    AdminFormField(
                      controller: faculty,
                      label: 'Facultad o departamento',
                    ),
                    AdminFormField(
                      controller: duration,
                      label: 'Duración en semestres',
                      keyboard: TextInputType.number,
                    ),
                    if (program != null)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Programa activo',
                          style: TextStyle(fontSize: 13),
                        ),
                        value: active,
                        onChanged: (value) =>
                            setStateDialog(() => active = value),
                      ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                if (!key.currentState!.validate()) return;
                final body = <String, Object>{
                  'nombre': name.text.trim(),
                  'codigo': code.text.trim(),
                  'facultad': faculty.text.trim(),
                  'duracion_semestres': int.tryParse(duration.text) ?? 0,
                  if (program != null) 'activo': active,
                };
                try {
                  if (program == null) {
                    await widget.service.crearPrograma(body);
                  } else {
                    await widget.service.actualizarPrograma(program.id, body);
                  }
                  if (context.mounted) Navigator.pop(context, true);
                } catch (error) {
                  if (context.mounted) showAdminDialogError(context, error);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (result == true) _refresh();
    code.dispose();
    name.dispose();
    faculty.dispose();
    duration.dispose();
  }
}
