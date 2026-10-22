import 'package:flutter/material.dart';

import '../core/network/api_exception.dart';
import '../core/theme/app_colors.dart';
import '../core/validators.dart';
import '../core/widgets/async_view.dart';
import '../core/widgets/page_list.dart';
import '../core/widgets/responsive_grid.dart';
import '../estudiantes/estudiantes_service.dart';
import '../estudiantes/models.dart';
import 'models.dart';
import 'requisito_card.dart';
import 'requisitos_service.dart';

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
  });

  final EstudiantesService estudiantes;
  final RequisitosService requisitos;

  @override
  State<GestionRequisitosScreen> createState() => _GestionRequisitosScreenState();
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

  Future<_DatosGestion> _cargar(String codigo) async {
    final resultados = await Future.wait<Object>([
      widget.estudiantes.obtener(codigo),
      widget.requisitos.obtenerRequisitos(codigo),
    ]);
    return _DatosGestion(resultados[0] as Estudiante, resultados[1] as List<Requisito>);
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
              child: Form(
                key: _formKey,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    FilledButton(onPressed: _buscar, child: const Text('Buscar')),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: consulta == null
              ? const Center(child: Text('Busca un estudiante para gestionar sus requisitos.'))
              : AsyncView<_DatosGestion>(
                  key: ValueKey(consulta),
                  load: () => _cargar(consulta),
                  builder: (context, datos) =>
                      _ResultadoGestion(datos: datos, service: widget.requisitos),
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
    if (!identical(anterior.datos, widget.datos)) _items = [...widget.datos.requisitos];
  }

  Future<void> _cambiar(Requisito requisito, EstadoRequisito nuevo) async {
    if (nuevo == requisito.estado) return;
    final mensajero = ScaffoldMessenger.of(context);
    setState(() => _ocupados.add(requisito.id));
    try {
      final actualizado = await widget.service.actualizarEstado(requisito.id, nuevo);
      if (!mounted) return;
      setState(() => _items = [for (final r in _items) r.id == actualizado.id ? actualizado : r]);
      mensajero.showSnackBar(const SnackBar(content: Text('Estado actualizado.')));
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
    return PageList(children: [
      Text(estudiante.nombre, style: tema.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
      Text('${estudiante.programa} · ${estudiante.codigoEstudiantil}',
          style: tema.bodyMedium?.copyWith(color: AppColors.textMuted)),
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
                  onChanged: _ocupados.contains(r.id) ? null : (v) => v == null ? null : _cambiar(r, v),
                  items: [
                    for (final e in EstadoRequisito.values)
                      DropdownMenuItem(value: e, child: Text(e.etiqueta)),
                  ],
                ),
              ),
          ],
        ),
    ]);
  }
}
