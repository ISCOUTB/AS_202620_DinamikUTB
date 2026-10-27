import 'package:flutter/material.dart';

import 'package:frontend/administracion/service/admin_service.dart';
import 'package:frontend/administracion/widgets/student_registration_dialog.dart';
import 'package:frontend/core/network/api_exception.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/validators.dart';
import 'package:frontend/core/widgets/async_view.dart';
import 'package:frontend/core/widgets/page_list.dart';
import 'package:frontend/core/widgets/responsive_grid.dart';
import 'package:frontend/estudiantes/estudiantes_service.dart';
import 'package:frontend/estudiantes/models.dart';
import 'package:frontend/requisitos/models.dart';
import 'package:frontend/requisitos/requisito_card.dart';
import 'package:frontend/requisitos/requisitos_service.dart';

class _DatosGestion {
  const _DatosGestion(this.estudiante, this.requisitos);

  final Estudiante estudiante;
  final List<Requisito> requisitos;
}

/// Permite buscar un estudiante y actualizar el estado de sus requisitos.
class GestionRequisitosScreen extends StatefulWidget {
  const GestionRequisitosScreen({
    super.key,
    required this.estudiantes,
    required this.requisitos,
    required this.administracion,
  });

  final EstudiantesService estudiantes;
  final RequisitosService requisitos;
  final AdminService administracion;

  @override
  State<GestionRequisitosScreen> createState() =>
      _GestionRequisitosScreenState();
}

class _GestionRequisitosScreenState extends State<GestionRequisitosScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codigo = TextEditingController();
  String? _consulta;

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  void _buscar() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _consulta = _codigo.text.trim());
  }

  Future<void> _registrarEstudiante() async {
    final messenger = ScaffoldMessenger.of(context);
    final creado = await StudentRegistrationDialog.show(
      context,
      widget.administracion,
    );
    if (!mounted || creado != true) return;
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Cuenta creada e inactiva. Administración debe verificarla, activarla y facilitar el acceso inicial.',
        ),
      ),
    );
  }

  Future<_DatosGestion> _cargar(String codigo) async {
    final resultados = await Future.wait<Object>([
      widget.estudiantes.obtener(codigo),
      widget.requisitos.obtenerRequisitos(codigo),
    ]);
    return _DatosGestion(
      resultados[0] as Estudiante,
      resultados[1] as List<Requisito>,
    );
  }

  @override
  Widget build(BuildContext context) {
    final consulta = _consulta;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final search = Form(
                    key: _formKey,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _codigo,
                            maxLength: 20,
                            textInputAction: TextInputAction.search,
                            onFieldSubmitted: (_) => _buscar(),
                            validator: Validators.codigoEstudiantil,
                            decoration: const InputDecoration(
                              labelText: 'Código estudiantil',
                              prefixIcon: Icon(Icons.search),
                              counterText: '',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: _buscar,
                          child: const Text('Buscar'),
                        ),
                      ],
                    ),
                  );
                  final create = OutlinedButton.icon(
                    onPressed: _registrarEstudiante,
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                    label: const Text('Registrar estudiante'),
                  );
                  return constraints.maxWidth >= 760
                      ? Row(
                          children: [
                            Expanded(child: search),
                            const SizedBox(width: 16),
                            create,
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            search,
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: create,
                            ),
                          ],
                        );
                },
              ),
            ),
          ),
        ),
        Expanded(
          child: consulta == null
              ? const Center(
                  child: Text(
                    'Busca un estudiante para gestionar sus requisitos.',
                  ),
                )
              : AsyncView<_DatosGestion>(
                  key: ValueKey(consulta),
                  load: () => _cargar(consulta),
                  builder: (context, datos) => _ResultadoGestion(
                    datos: datos,
                    service: widget.requisitos,
                  ),
                ),
        ),
      ],
    );
  }
}

class _ResultadoGestion extends StatefulWidget {
  const _ResultadoGestion({required this.datos, required this.service});

  final _DatosGestion datos;
  final RequisitosService service;

  @override
  State<_ResultadoGestion> createState() => _ResultadoGestionState();
}

class _ResultadoGestionState extends State<_ResultadoGestion> {
  late List<Requisito> _items = [...widget.datos.requisitos];
  final Set<int> _ocupados = {};

  @override
  void didUpdateWidget(covariant _ResultadoGestion anterior) {
    super.didUpdateWidget(anterior);
    if (!identical(anterior.datos, widget.datos)) {
      _items = [...widget.datos.requisitos];
    }
  }

  Future<void> _cambiar(Requisito requisito, EstadoRequisito nuevo) async {
    if (nuevo == requisito.estado) return;
    final mensajero = ScaffoldMessenger.of(context);
    setState(() => _ocupados.add(requisito.id));
    try {
      final actualizado = await widget.service.actualizarEstado(
        requisito.id,
        nuevo,
      );
      if (!mounted) return;
      setState(
        () => _items = [
          for (final r in _items) r.id == actualizado.id ? actualizado : r,
        ],
      );
      mensajero.showSnackBar(
        const SnackBar(content: Text('Estado actualizado.')),
      );
    } on ApiException catch (e) {
      mensajero.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _ocupados.remove(requisito.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final estudiante = widget.datos.estudiante;
    final tema = Theme.of(context).textTheme;
    return PageList(
      children: [
        Text(
          estudiante.nombre,
          style: tema.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(
          '${estudiante.programa} · ${estudiante.codigoEstudiantil}',
          style: tema.bodyMedium?.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),
        if (_items.isEmpty)
          const Text('Este estudiante no tiene requisitos registrados.')
        else
          ResponsiveGrid(
            minTileWidth: 320,
            children: [
              for (final r in _items)
                RequisitoCard(
                  requisito: r,
                  pie: DropdownButton<EstadoRequisito>(
                    isExpanded: true,
                    value: r.estado,
                    onChanged: _ocupados.contains(r.id)
                        ? null
                        : (v) => v == null ? null : _cambiar(r, v),
                    items: [
                      for (final e in EstadoRequisito.values)
                        DropdownMenuItem(value: e, child: Text(e.etiqueta)),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
