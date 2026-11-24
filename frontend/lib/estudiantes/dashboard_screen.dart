import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/network/api_exception.dart';
import 'package:frontend/curriculo/malla_screen.dart';
import 'package:frontend/curriculo/malla_service.dart';
import 'package:frontend/requisitos/requisitos_service.dart';
import 'estudiantes_service.dart';
import 'models.dart';
import 'progreso_models.dart';
import 'progreso_service.dart';
import 'widgets/asignaturas_panel.dart';
import 'widgets/astrolabio.dart';
import 'widgets/bitacora_logros.dart';
import 'widgets/dash_background.dart';
import 'widgets/dash_hero.dart';
import 'widgets/dash_sheets.dart';
import 'widgets/dash_style.dart';
import 'widgets/elevation_chart.dart';
import 'widgets/hito_bar.dart';

class _Datos {
  const _Datos(this.estudiante, this.progreso, this.ruta);

  final Estudiante estudiante;
  final ProgresoMalla progreso;
  final List<RutaRequisito> ruta;
}

/// Panorama del estudiante: avance de la malla, requisitos de grado con su
/// guía, lo que sigue y la bitácora de logros. El fondo pasa de morado a
/// naranja a medida que se baja.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.estudiantes,
    required this.requisitos,
    required this.codigoEstudiantil,
  });

  final EstudiantesService estudiantes;
  // Se conserva para no cambiar la firma que usa AuthGate.
  final RequisitosService requisitos;
  final String codigoEstudiantil;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final ProgresoService _progreso = ProgresoService(context.read<ApiClient>());
  late Future<_Datos> _futuro;
  final _controller = ScrollController();
  final _scrollP = ValueNotifier<double>(0);
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );
  bool _iniciada = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_alDesplazar);
    _futuro = _cargar();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciada) return;
    _iniciada = true;
    if (!MediaQuery.disableAnimationsOf(context)) _ambient.repeat();
  }

  @override
  void dispose() {
    _controller.removeListener(_alDesplazar);
    _controller.dispose();
    _scrollP.dispose();
    _ambient.dispose();
    super.dispose();
  }

  void _alDesplazar() {
    if (!_controller.hasClients) return;
    final pos = _controller.position;
    if (!pos.hasContentDimensions) return;
    final tramo = math.min(pos.maxScrollExtent, 2600.0);
    _scrollP.value = tramo <= 0 ? 0 : (pos.pixels / tramo).clamp(0.0, 1.0).toDouble();
  }

  Future<_Datos> _cargar() async {
    final r = await Future.wait<Object>([
      widget.estudiantes.obtener(widget.codigoEstudiantil),
      _progreso.obtenerProgreso(widget.codigoEstudiantil),
      _progreso.obtenerRuta(widget.codigoEstudiantil),
    ]);
    return _Datos(
      r[0] as Estudiante,
      r[1] as ProgresoMalla,
      r[2] as List<RutaRequisito>,
    );
  }

  Future<void> _recargar() {
    final nuevo = _cargar();
    setState(() => _futuro = nuevo);
    return nuevo.then<void>((_) {}, onError: (Object _) {});
  }

  void _abrirMalla(_Datos d) {
    final servicio = context.read<MallaService>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Malla curricular')),
          body: MallaScreen(
            service: servicio,
            programa: d.progreso.programa,
            semestreActual: d.estudiante.semestre,
          ),
        ),
      ),
    );
  }

  List<Hito> _hitos(List<RutaRequisito> ruta) {
    final porPct = <int, List<String>>{};
    for (final r in ruta) {
      final pct = r.porcentajeCreditosRequerido;
      if (pct != null) porPct.putIfAbsent(pct, () => []).add(r.nombre);
    }
    final claves = porPct.keys.toList()..sort();
    return [
      for (final k in claves) Hito(k.toDouble(), 'Habilita ${_unir(porPct[k]!)}'),
      const Hito(100, 'Grado UTB'),
    ];
  }

  String _unir(List<String> n) => n.length == 1
      ? n.first
      : '${n.sublist(0, n.length - 1).join(', ')} y ${n.last}';

  (String, String?) _mensaje(_Datos d, List<Hito> hitos) {
    final r = d.progreso.resumen;
    if (r.creditosTotales > 0 && r.creditosAprobados >= r.creditosTotales) {
      return ('¡Completaste tu plan de estudios!', 'Ahora cierra los requisitos de grado.');
    }
    final orden = [...hitos.where((h) => h.pct < 100)]..sort((a, b) => a.pct.compareTo(b.pct));
    for (final h in orden) {
      final faltan = (r.creditosTotales * h.pct.round() + 99) ~/ 100 - r.creditosAprobados;
      if (faltan > 0) {
        return ('Te faltan $faltan créditos para el ${h.pct.toStringAsFixed(0)} %.', h.etiqueta);
      }
    }
    final pendientes = d.ruta.where((x) => x.estado != 'cumplido').length;
    return (
      pendientes == 0
          ? '¡Todos tus requisitos están cumplidos!'
          : 'Ya alcanzaste los umbrales de créditos.',
      pendientes == 0 ? null : 'Quedan $pendientes requisitos por cerrar: míralos más abajo.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DashBackground(scroll: _scrollP, ambient: _ambient),
        FutureBuilder<_Datos>(
          future: _futuro,
          builder: (context, snap) {
            if (snap.hasError) {
              final e = snap.error;
              return _Error(
                mensaje: e is ApiException
                    ? e.message
                    : 'No se pudo cargar tu avance. Intenta de nuevo.',
                onReintentar: _recargar,
              );
            }
            if (!snap.hasData) return const _Cargando();
            return _contenido(context, snap.data!);
          },
        ),
      ],
    );
  }

  Widget _contenido(BuildContext context, _Datos d) {
    final p = d.progreso;
    final r = p.resumen;
    final compacto = esCompacto(context);
    final cumplidos = d.ruta.where((x) => x.estado == 'cumplido').length;
    final reqPct = d.ruta.isEmpty ? 0.0 : cumplidos * 100 / d.ruta.length;
    final hitos = _hitos(d.ruta);
    final (mensaje, sub) = _mensaje(d, hitos);
    final enCursoPorNivel = <int, int>{};
    for (final c in p.cursos) {
      if (c.enCurso) enCursoPorNivel[c.nivel] = (enCursoPorNivel[c.nivel] ?? 0) + c.creditos;
    }
    final padH = compacto ? 16.0 : 28.0;

    Widget ancho(Widget hijo) => Center(
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1100), child: hijo),
    );
    Widget seccion(String titulo, String? subtitulo, Widget hijo) => ancho(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(titulo: titulo, subtitulo: subtitulo),
          const SizedBox(height: 16),
          hijo,
        ],
      ),
    );
    const espacio = SizedBox(height: 40);

    return RefreshIndicator(
      color: Dash.cobalt,
      backgroundColor: Colors.white,
      onRefresh: _recargar,
      child: ListView(
        controller: _controller,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(padH, 24, padH, 0),
        children: [
          ancho(
            DashHero(
              nombre: d.estudiante.nombre,
              programa: p.programa,
              codigo: d.estudiante.codigoEstudiantil,
              semestre: d.estudiante.semestre,
              periodo: p.periodoActual,
              mensaje: mensaje,
              submensaje: sub,
            ),
          ),
          const SizedBox(height: 28),
          ancho(
            Astrolabio(
              creditosPct: r.porcentajeGlobal,
              requisitosPct: reqPct,
              creditosAprobados: r.creditosAprobados,
              creditosEnCurso: r.creditosEnCurso,
              creditosPendientes: r.creditosPendientes,
              creditosTotales: r.creditosTotales,
              requisitosCumplidos: cumplidos,
              requisitosTotal: d.ruta.length,
              semestresRestantes: r.semestresRestantes,
              promedio: r.promedioAcumulado,
              periodoGrado: r.periodoGradoEstimado,
              hitos: [for (final h in hitos) h.pct],
            ),
          ),
          espacio,
          seccion(
            'Tu recorrido por semestre',
            'Cada punto es un semestre de la malla. Toca uno para ver sus materias.',
            GlassPanel(
              padding: EdgeInsets.fromLTRB(compacto ? 10 : 18, 18, compacto ? 10 : 18, 10),
              child: ElevationChart(
                niveles: p.niveles,
                enCursoPorNivel: enCursoPorNivel,
                onSeleccion: (nivel) => mostrarSemestre(
                  context,
                  nivel: nivel,
                  resumen: p.niveles.where((n) => n.nivel == nivel).firstOrNull,
                  cursos: p.cursos.where((c) => c.nivel == nivel).toList(),
                  onVerMalla: () => _abrirMalla(d),
                ),
              ),
            ),
          ),
          espacio,
          seccion(
            'Camino a la graduación',
            'Los hitos de créditos que habilitan Saber Pro, la práctica y la opción de grado.',
            GlassPanel(
              padding: const EdgeInsets.all(22),
              child: HitoBar(
                porcentaje: r.porcentajeGlobal,
                creditosAprobados: r.creditosAprobados,
                creditosTotales: r.creditosTotales,
                hitos: hitos,
              ),
            ),
          ),
          espacio,
          seccion(
            'Qué sigue en tu malla',
            'Lo que puedes matricular hoy y lo que está esperando un prerrequisito.',
            AsignaturasPanel(cursos: p.cursos),
          ),
          espacio,
          seccion(
            'Bitácora de logros',
            'Todo lo que ya sellaste con ✕, del más reciente al más antiguo.',
            BitacoraLogros(cursos: p.cursos, requisitos: d.ruta),
          ),
          const SizedBox(height: 36),
          ancho(const _Pie()),
        ],
      ),
    );
  }
}

class _Pie extends StatelessWidget {
  const _Pie();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text('Cada ✕ te acerca a tu grado.', style: Dash.display(24)),
      const SizedBox(height: 14),
      Image.asset(
        DashAssets.siluetas,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stack) => const SizedBox(height: 80),
      ),
    ],
  );
}

class _Cargando extends StatefulWidget {
  const _Cargando();

  @override
  State<_Cargando> createState() => _CargandoState();
}

class _CargandoState extends State<_Cargando> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );
  bool _iniciada = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciada) return;
    _iniciada = true;
    if (!MediaQuery.disableAnimationsOf(context)) _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _c,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, -14 * Curves.easeInOut.transform(_c.value)),
            child: child,
          ),
          child: Image.asset(
            DashAssets.head,
            width: 96,
            errorBuilder: (context, error, stack) => const SizedBox(width: 96, height: 96),
          ),
        ),
        const SizedBox(height: 18),
        Text('Armando tu mapa académico…', style: Dash.display(22)),
        const SizedBox(height: 14),
        const SizedBox(
          width: 150,
          child: LinearProgressIndicator(color: Dash.aqua, backgroundColor: Colors.white24),
        ),
      ],
    ),
  );
}

class _Error extends StatelessWidget {
  const _Error({required this.mensaje, required this.onReintentar});

  final String mensaje;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: GlassPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.explore_off_outlined, color: Dash.amber, size: 44),
              const SizedBox(height: 12),
              Text(mensaje, textAlign: TextAlign.center, style: Dash.body(15)),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Dash.aqua,
                  foregroundColor: Dash.ink,
                ),
                onPressed: onReintentar,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
