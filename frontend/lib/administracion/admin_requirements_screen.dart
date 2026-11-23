
import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/administracion/service/admin_service.dart';
import 'widgets/admin_common_widgets.dart';

class AdminRequirementsScreen extends StatefulWidget {
  const AdminRequirementsScreen({
    super.key,
    required this.service,
  });

  final AdminService service;

  @override
  State<AdminRequirementsScreen> createState() =>
      _AdminRequirementsPageState();
}

class _AdminRequirementsPageState
    extends State<AdminRequirementsScreen> {
  late Future<List<AdminRequirement>> _future =
      widget.service.requisitos();

  void _refresh() {
    setState(() {
      _future = widget.service.requisitos();
    });
  }

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
                        side: const BorderSide(
                          color: AppColors.border,
                        ),
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
                          '${item.programa} · Etapa recomendada: semestre ${item.semestre}\n'
                          '${item.descripcion.isEmpty ? 'Sin descripción' : item.descripcion} · '
                          '${item.obligatorio ? 'Obligatorio' : 'Opcional'}',
                          style: const TextStyle(
                            fontSize: 10,
                            height: 1.6,
                          ),
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          tooltip: 'Editar requisito',
                          onPressed: () => _edit(context, item),
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 18,
                          ),
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
    final programs = await widget.service.programas(
      administrar: true,
    );

    if (!context.mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _RequirementFormDialog(
        service: widget.service,
        programs: programs,
        requirement: requirement,
      ),
    );

    if (!mounted) return;

    if (result == true) {
      _refresh();
    }
  }
}

class _RequirementFormDialog extends StatefulWidget {
  const _RequirementFormDialog({
    required this.service,
    required this.programs,
    this.requirement,
  });

  final AdminService service;
  final List<AdminProgram> programs;
  final AdminRequirement? requirement;

  @override
  State<_RequirementFormDialog> createState() =>
      _RequirementFormDialogState();
}

class _RequirementFormDialogState
    extends State<_RequirementFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _semester;

  int? _programId;
  late bool _mandatory;
  late bool _active;

  bool _saving = false;

  bool get _isEditing => widget.requirement != null;

  @override
  void initState() {
    super.initState();

    final requirement = widget.requirement;

    _name = TextEditingController(
      text: requirement?.nombre ?? '',
    );

    _description = TextEditingController(
      text: requirement?.descripcion ?? '',
    );

    _semester = TextEditingController(
      text: '${requirement?.semestre ?? 1}',
    );

    final hasProgram = widget.programs.any(
      (program) => program.id == requirement?.programaId,
    );

    _programId = hasProgram
        ? requirement!.programaId
        : widget.programs.isNotEmpty
            ? widget.programs.first.id
            : null;

    _mandatory = requirement?.obligatorio ?? true;
    _active = requirement?.activo ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _semester.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
    });

    final payload = <String, Object>{
      'programa_id': _programId!,
      'nombre': _name.text.trim(),
      'descripcion': _description.text.trim(),
      'semestre_recomendado':
          int.tryParse(_semester.text) ?? 1,
      'obligatorio': _mandatory,
      if (_isEditing) 'activo': _active,
    };

    try {
      if (_isEditing) {
        await widget.service.actualizarRequisito(
          widget.requirement!.id,
          payload,
        );
      } else {
        await widget.service.crearRequisito(payload);
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      showAdminDialogError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isEditing ? 'Editar requisito' : 'Crear requisito',
      ),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AdminFormField(
                  controller: _name,
                  label: 'Nombre del requisito',
                ),

                AdminFormField(
                  controller: _description,
                  label: 'Descripción',
                  maxLines: 3,
                ),

                DropdownButtonFormField<int>(
                  initialValue: _programId,
                  borderRadius: BorderRadius.circular(10),
                  decoration: adminFilterInputDecoration(
                    'Programa académico',
                  ),
                  items: [
                    for (final program in widget.programs)
                      DropdownMenuItem(
                        value: program.id,
                        child: Text(program.nombre),
                      ),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) {
                          setState(() {
                            _programId = value;
                          });
                        },
                  validator: (value) => value == null
                      ? 'Crea primero un programa.'
                      : null,
                ),

                const SizedBox(height: 14),

                AdminFormField(
                  controller: _semester,
                  label: 'Semestre recomendado',
                  keyboard: TextInputType.number,
                ),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Obligatorio',
                    style: TextStyle(fontSize: 13),
                  ),
                  value: _mandatory,
                  onChanged: _saving
                      ? null
                      : (value) {
                          setState(() {
                            _mandatory = value;
                          });
                        },
                ),

                if (_isEditing)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Requisito activo',
                      style: TextStyle(fontSize: 13),
                    ),
                    value: _active,
                    onChanged: _saving
                        ? null
                        : (value) {
                            setState(() {
                              _active = value;
                            });
                          },
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving
              ? null
              : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),

        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
