import 'package:flutter/material.dart';
import 'package:frontend/core/network/api_exception.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/validators.dart';
import 'package:frontend/administracion/service/admin_service.dart';

class StudentEditDialog extends StatefulWidget {
  const StudentEditDialog({
    super.key,
    required this.service,
    required this.student,
  });

  final AdminService service;
  final AdminStudent student;

  static Future<bool?> show(
    BuildContext context, {
    required AdminService service,
    required AdminStudent student,
  }) => showDialog<bool>(
    context: context,
    builder: (_) => StudentEditDialog(service: service, student: student),
  );

  @override
  State<StudentEditDialog> createState() => _StudentEditDialogState();
}

class _StudentEditDialogState extends State<StudentEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.student.nombre);
  late final _email = TextEditingController(text: widget.student.email);
  late final _semester = TextEditingController(
    text: '${widget.student.semestre ?? 1}',
  );

  late Future<List<AdminProgram>> _programs;
  String? _program;
  late bool _active = widget.student.activo;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _programs = widget.service.programas();
    _program = widget.student.programa;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _semester.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final programsList = await _programs;
      final selectedProgram = _program ?? programsList.firstOrNull?.nombre;

      if (selectedProgram == null) {
        setState(() => _error = 'Selecciona un programa académico válido.');
        return;
      }

      final payload = <String, Object>{
        'nombre': _name.text.trim(),
        'email': _email.text.trim(),
        'codigo_estudiantil': widget.student.codigo,
        'programa': selectedProgram,
        'semestre': int.parse(_semester.text),
        'activo': _active,
      };

      await widget.service.actualizarEstudiante(widget.student.codigo, payload);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) setState(() => _error = 'No se pudo actualizar: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    title: const Text('Editar estudiante'),
    content: SizedBox(
      width: 460,
      child: FutureBuilder<List<AdminProgram>>(
        future: _programs,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text(
              'Error al cargar programas: ${snapshot.error}',
              style: const TextStyle(fontSize: 12, color: AppColors.danger),
            );
          }
          if (!snapshot.hasData) {
            return const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final programs = snapshot.data!;
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_error != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.dangerBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  TextFormField(
                    controller: _name,
                    enabled: !_saving,
                    decoration: InputDecoration(
                      labelText: 'Nombres completos',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (v) => v == null || v.trim().length < 3
                        ? 'Ingresa el nombre completo.'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _email,
                    enabled: !_saving,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Correo institucional',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: Validators.correoInstitucional,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    initialValue: widget.student.codigo,
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: 'Código estudiantil (no editable)',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: programs.any((p) => p.nombre == _program)
                        ? _program
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    decoration: InputDecoration(
                      labelText: 'Programa académico',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: [
                      for (final p in programs)
                        DropdownMenuItem(
                          value: p.nombre,
                          child: Text(
                            p.nombre,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                    ],
                    onChanged: _saving
                        ? null
                        : (v) => setState(() => _program = v),
                  ),

                  // ESPACIO CORREGIDO
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _semester,
                    enabled: !_saving,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Semestre actual',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (v) {
                      final sem = int.tryParse(v ?? '');
                      return sem == null || sem < 1 || sem > 12
                          ? 'Semestre entre 1 y 12.'
                          : null;
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Cuenta activa',
                      style: TextStyle(fontSize: 13),
                    ),
                    value: _active,
                    onChanged: _saving
                        ? null
                        : (v) => setState(() => _active = v),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: _saving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('Guardar cambios'),
      ),
    ],
  );
}
