import 'package:flutter/material.dart';
import 'package:frontend/core/network/api_exception.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/validators.dart';
import 'package:frontend/administracion/service/admin_service.dart';

class StudentRegistrationDialog extends StatefulWidget {
  const StudentRegistrationDialog({super.key, required this.service});

  final AdminService service;

  static Future<bool?> show(BuildContext context, AdminService service) =>
      showDialog<bool>(
        context: context,
        builder: (_) => StudentRegistrationDialog(service: service),
      );

  @override
  State<StudentRegistrationDialog> createState() =>
      _StudentRegistrationDialogState();
}

class _StudentRegistrationDialogState extends State<StudentRegistrationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _semester = TextEditingController(text: '1');
  late Future<List<AdminProgram>> _programs;
  String? _program;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _programs = widget.service.programas();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _code.dispose();
    _semester.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final program = _program ?? (await _programs).firstOrNull?.nombre;
      if (program == null) {
        setState(() => _error = 'Selecciona un programa académico activo.');
        return;
      }
      await widget.service.crearEstudiante({
        'nombre': _name.text.trim(),
        'email': _email.text.trim(),
        'codigo_estudiantil': _code.text.trim(),
        'programa': program,
        'semestre': int.parse(_semester.text),
      });
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'No se pudo crear la cuenta: $error');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    title: const Text('Registrar estudiante'),
    content: SizedBox(
      width: 460,
      child: FutureBuilder<List<AdminProgram>>(
        future: _programs,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  snapshot.error is ApiException
                      ? (snapshot.error! as ApiException).message
                      : 'No se pudieron cargar los programas.',
                  style: const TextStyle(color: AppColors.danger, fontSize: 12),
                ),
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _programs = widget.service.programas()),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reintentar'),
                ),
              ],
            );
          }
          if (!snapshot.hasData) {
            return const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final programs = snapshot.data!;
          if (programs.isEmpty) {
            return const Text(
              'No hay programas activos. Crea un programa académico antes de registrar estudiantes.',
              style: TextStyle(fontSize: 12),
            );
          }
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_error != null) ...[
                    _DialogError(message: _error!),
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
                    validator: (value) =>
                        value == null || value.trim().length < 3
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
                      hintText: 'ejemplo@utb.edu.co',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: Validators.correoInstitucional,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _code,
                    enabled: !_saving,
                    decoration: InputDecoration(
                      labelText: 'Código estudiantil',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: Validators.codigoEstudiantil,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _program ?? programs.first.nombre,
                    borderRadius: BorderRadius.circular(12),
                    decoration: InputDecoration(
                      labelText: 'Programa académico',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: [
                      for (final program in programs)
                        DropdownMenuItem(
                          value: program.nombre,
                          child: Text(
                            program.nombre,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                    ],
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _program = value),
                  ),

                  // ESPACIO CORREGIDO ENTRE PROGRAMA Y SEMESTRE
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
                    validator: (value) {
                      final semester = int.tryParse(value ?? '');
                      return semester == null || semester < 1 || semester > 12
                          ? 'Ingresa un semestre entre 1 y 12.'
                          : null;
                    },
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
            : const Text('Crear cuenta'),
      ),
    ],
  );
}

class _DialogError extends StatelessWidget {
  const _DialogError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: AppColors.dangerBg,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      message,
      style: const TextStyle(color: AppColors.danger, fontSize: 12),
    ),
  );
}
