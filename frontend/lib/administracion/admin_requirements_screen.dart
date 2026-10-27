import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/administracion/service/admin_service.dart';
import 'widgets/admin_common_widgets.dart';

class AdminRequirementsScreen extends StatefulWidget {
  const AdminRequirementsScreen({super.key, required this.service});
  final AdminService service;

  @override
  State<AdminRequirementsScreen> createState() => _AdminRequirementsPageState();
}

class _AdminRequirementsPageState extends State<AdminRequirementsScreen> {
  late Future<List<AdminRequirement>> _future = widget.service.requisitos();

  void _refresh() => setState(() => _future = widget.service.requisitos());

  @override
  Widget build(BuildContext context) => AdminPageFrame(
    title: 'Requisitos de grado',
    subtitle:
        'Administra el catálogo por programa; cada requisito nuevo se asigna a sus estudiantes.',
    trailing: FilledButton.icon(
      onPressed: () => _edit(context),
      icon: const Icon(Icons.add, size: 16),
      label: const Text('Crear requisito'),
    ),
    children: [
      FutureBuilder<List<AdminRequirement>>(
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
              icon: Icons.fact_check_outlined,
              title: 'No hay requisitos en el catálogo',
              detail:
                  'Agrega los requisitos oficiales para asignarlos por programa.',
            );
          }
          return Column(
            children: [
              for (final item in snapshot.data!)
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
                        Icons.checklist,
                        color: AppColors.cyan,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      item.nombre,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      '${item.programa} · Etapa recomendada: semestre ${item.semestre}\n${item.descripcion.isEmpty ? 'Sin descripción' : item.descripcion} · ${item.obligatorio ? 'Obligatorio' : 'Opcional'}',
                      style: const TextStyle(fontSize: 10, height: 1.6),
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      tooltip: 'Editar requisito',
                      onPressed: () => _edit(context, item),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ],
  );

  Future<void> _edit(
    BuildContext context, [
    AdminRequirement? requirement,
  ]) async {
    final programs = await widget.service.programas(administrar: true);
    if (!context.mounted) return;

    final key = GlobalKey<FormState>();
    final name = TextEditingController(text: requirement?.nombre ?? '');
    final description = TextEditingController(
      text: requirement?.descripcion ?? '',
    );
    final semester = TextEditingController(
      text: '${requirement?.semestre ?? 1}',
    );
    var programId = programs.any((p) => p.id == requirement?.programaId)
        ? requirement!.programaId
        : programs.firstOrNull?.id;
    var mandatory = requirement?.obligatorio ?? true;
    var active = requirement?.activo ?? true;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            requirement == null ? 'Crear requisito' : 'Editar requisito',
          ),
          content: SizedBox(
            width: 460,
            child: Form(
              key: key,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AdminFormField(
                      controller: name,
                      label: 'Nombre del requisito',
                    ),
                    AdminFormField(
                      controller: description,
                      label: 'Descripción',
                      maxLines: 3,
                    ),

                    // Selector de Programa con borde redondeado
                    DropdownButtonFormField<int>(
                      initialValue: programId,
                      borderRadius: BorderRadius.circular(10),
                      decoration: adminFilterInputDecoration(
                        'Programa académico',
                      ),
                      items: [
                        for (final p in programs)
                          DropdownMenuItem(value: p.id, child: Text(p.nombre)),
                      ],
                      onChanged: (value) =>
                          setDialogState(() => programId = value),
                      validator: (value) =>
                          value == null ? 'Crea primero un programa.' : null,
                    ),

                    // ESPACIO CORREGIDO ENTRE PROGRAMA Y SEMESTRE
                    const SizedBox(height: 14),

                    AdminFormField(
                      controller: semester,
                      label: 'Semestre recomendado',
                      keyboard: TextInputType.number,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Obligatorio',
                        style: TextStyle(fontSize: 13),
                      ),
                      value: mandatory,
                      onChanged: (value) =>
                          setDialogState(() => mandatory = value),
                    ),
                    if (requirement != null)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Requisito activo',
                          style: TextStyle(fontSize: 13),
                        ),
                        value: active,
                        onChanged: (value) =>
                            setDialogState(() => active = value),
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
                final payload = <String, Object>{
                  'programa_id': programId!,
                  'nombre': name.text.trim(),
                  'descripcion': description.text.trim(),
                  'semestre_recomendado': int.tryParse(semester.text) ?? 1,
                  'obligatorio': mandatory,
                  if (requirement != null) 'activo': active,
                };
                try {
                  if (requirement == null) {
                    await widget.service.crearRequisito(payload);
                  } else {
                    await widget.service.actualizarRequisito(
                      requirement.id,
                      payload,
                    );
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
    name.dispose();
    description.dispose();
    semester.dispose();
  }
}
