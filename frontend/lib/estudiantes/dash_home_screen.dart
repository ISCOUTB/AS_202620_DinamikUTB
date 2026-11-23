import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:frontend/core/widgets/async_view.dart';
import 'package:frontend/core/widgets/page_list.dart';
import 'package:frontend/core/widgets/responsive_grid.dart';
import 'package:frontend/requisitos/models.dart';
import 'package:frontend/requisitos/requisitos_service.dart';

import 'estudiantes_service.dart';
import 'models.dart';
import 'progreso_models.dart';
import 'progreso_service.dart';
import 'widgets/astrolabio.dart';
import 'widgets/dash_background.dart';
import 'widgets/dash_hero.dart';
import 'widgets/dash_motion.dart';
import 'widgets/dash_style.dart';
import 'widgets/sello_x.dart';

/// Inicio del estudiante: la pantalla «chévere» del panorama.
///
/// Dos capas apiladas: el fondo que arranca con el morado de la bienvenida
/// y se tiñe de naranja (el de «¿Olvidaste tu contraseña?») al bajar, y
/// encima el contenido —saludo con la mascota verde, astrolabio con la cara
/// sobre el reloj, cifras del avance, niveles del plan, logros sellados y
/// el pie de la promoción— que va apareciendo con [Reveal] al desplazarse.
class DashHomeScreen extends StatefulWidget {
  const DashHomeScreen({
    super.key,
    required this.estudiantes,
    required this.requisitos,
    required this.progreso,
    required this.codigoEstudiantil,
  });

  final EstudiantesService estudiantes;
  final RequisitosService requisitos;
  final ProgresoService progreso;
  final String codigoEstudiantil;

  @override
  State<DashHomeScreen> createState() => _DashHomeScreenState();
}

/// Todo lo que la pantalla pide al backend en una sola tanda.
class _DatosInicio {
  const _DatosInicio({
    required this.estudiante,
    required this.avance,
    required this.resumenRequisitos,
    required this.requisitos,
  });

  final Estudiante estudiante;
  final ProgresoMalla avance;
  final ResumenRequisitos resumenRequisitos;
  final List<Requisito> requisitos;
}

class _DashHomeScreenState extends State<DashHomeScreen>
    with SingleTickerProviderStateMixin {
  /// Respiración lenta del fondo: mueve orbes, anillos y la cara del reloj.
  late final AnimationController _ambiente = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  );

  /// Avance del scroll 0 → 1 que tiñe el degradado morado a naranja.
  final ValueNotifier<double> _scroll = ValueNotifier<double>(0);
  bool _arrancado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_arrancado) return;
    _arrancado = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _ambiente.value = 0.25;
    } else {
      _ambiente.repeat();
    }
  }

  @override
  void dispose() {
    _ambiente.dispose();
    _scroll.dispose();
    super.dispose();
  }

  bool _alDesplazar(ScrollNotification notificacion) {
    // Solo la lista principal; los scrollables anidados (leyendas, hojas)
    // no deben mover el degradado.
    if (notificacion.depth != 0) return false;
    final recorrido = notificacion.metrics;
    final total = recorrido.maxScrollExtent;
    _scroll.value = total <= 0 ? 0 : c01(recorrido.pixels / total);
    return false;
  }

  Future<_DatosInicio> _cargar() async {
    final respuestas = await Future.wait<Object>([
      widget.estudiantes.obtener(widget.codigoEstudiantil),
      widget.progreso.obtenerProgreso(widget.codigoEstudiantil),
      widget.requisitos.obtenerResumen(widget.codigoEstudiantil),
      widget.requisitos.obtenerRequisitos(widget.codigoEstudiantil),
    ]);
    return _DatosInicio(
      estudiante: respuestas[0] as Estudiante,
      avance: respuestas[1] as ProgresoMalla,
      resumenRequisitos: respuestas[2] as ResumenRequisitos,
      requisitos: respuestas[3] as List<Requisito>,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DashBackground(scroll: _scroll, ambient: _ambiente),
        NotificationListener<ScrollNotification>(
          onNotification: _alDesplazar,
          child: AsyncView<_DatosInicio>(
            load: _cargar,
            builder: (context, datos) => _contenido(datos),
          ),
        ),
      ],
    );
  }

  Widget _contenido(_DatosInicio datos) {
    return PageList(
      children: [
        _saludo(datos),
        const SizedBox(height: 26),
        _brujula(datos),
        const SizedBox(height: 28),
        _cifras(datos),
        const SizedBox(height: 28),
        _niveles(datos),
        const SizedBox(height: 28),
        _logros(datos),
        const SizedBox(height: 28),
        _cierre(datos),
      ],
    );
  }

  // ---------------------------------------------------------------- saludo

  Widget _saludo(_DatosInicio datos) {
    final resumen = datos.avance.resumen;
    final porcentaje = resumen.porcentajeGlobal;
    final mensaje = porcentaje <= 0
        ? 'Tu plan empieza hoy: estrena tu primer avance en la malla.'
        : 'Vas al ${_porcentaje1(porcentaje)} % del plan: '
              '${resumen.creditosAprobados} de ${resumen.creditosTotales} créditos.';
    final submensaje = resumen.creditosEnCurso > 0
        ? '${resumen.creditosEnCurso} créditos en curso · quedan '
              '${resumen.creditosPendientes} por cursar'
        : 'Este periodo no cursas créditos · te quedan '
              '${resumen.creditosPendientes} por cursar';
    return Reveal(
      child: DashHero(
        nombre: datos.estudiante.nombre,
        programa: datos.estudiante.programa,
        codigo: datos.estudiante.codigoEstudiantil,
        semestre: datos.estudiante.semestre,
        periodo: datos.avance.periodoActual,
        mensaje: mensaje,
        submensaje: submensaje,
      ),
    );
  }

  // -------------------------------------------------------------- astrolabio

  Widget _brujula(_DatosInicio datos) {
    final resumen = datos.avance.resumen;
    final requisitos = datos.resumenRequisitos;
    return Reveal(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            titulo: 'Tu brújula académica',
            subtitulo: 'Dos anillos, un solo destino: tu grado.',
          ),
          const SizedBox(height: 16),
          Astrolabio(
            creditosPct: resumen.porcentajeGlobal,
            requisitosPct: requisitos.porcentajeAvance,
            creditosAprobados: resumen.creditosAprobados,
            creditosEnCurso: resumen.creditosEnCurso,
            creditosPendientes: resumen.creditosPendientes,
            creditosTotales: resumen.creditosTotales,
            requisitosCumplidos: requisitos.cumplidos,
            requisitosTotal: requisitos.total,
            semestresRestantes: resumen.semestresRestantes,
            hitos: const [25.0, 50.0, 75.0, 100.0],
            promedio: resumen.promedioAcumulado,
            periodoGrado: resumen.periodoGradoEstimado,
            adorno: _caraDelReloj(),
          ),
        ],
      ),
    );
  }

  /// La cara 3D sobre el reloj: entra con un rebote y respira con el
  /// ambiente lento del fondo.
  Widget _caraDelReloj() {
    final imagen = Image.asset(
      DashAssets.head,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          const SizedBox(width: 78, height: 78),
    );
    return AnimatedBuilder(
      animation: _ambiente,
      builder: (context, child) {
        final t = _ambiente.value * 2 * math.pi;
        return Transform.translate(
          offset: Offset(math.sin(t) * 3, math.cos(t) * 4),
          child: child,
        );
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutBack,
        builder: (context, valor, child) =>
            Transform.scale(scale: 0.5 + 0.5 * valor, child: child),
        child: SizedBox(width: 82, height: 82, child: imagen),
      ),
    );
  }

  // ----------------------------------------------------------------- cifras

  Widget _cifras(_DatosInicio datos) {
    final resumen = datos.avance.resumen;
    final requisitos = datos.resumenRequisitos;
    return Reveal(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            titulo: 'Avance en números',
            subtitulo: 'Todo lo que vas acumulando, de un vistazo.',
          ),
          const SizedBox(height: 16),
          ResponsiveGrid(
            minTileWidth: 210,
            spacing: 12,
            children: [
              _Cifra(
                etiqueta: 'Créditos aprobados',
                valor: resumen.creditosAprobados.toDouble(),
                color: Dash.aqua,
                sufijo: ' cr',
                pie: 'de ${resumen.creditosTotales} del plan',
              ),
              _Cifra(
                etiqueta: 'Créditos en curso',
                valor: resumen.creditosEnCurso.toDouble(),
                color: Dash.amber,
                sufijo: ' cr',
                pie: resumen.creditosEnCurso > 0
                    ? 'este periodo'
                    : 'sin matrícula activa',
              ),
              _Cifra(
                etiqueta: 'Por cursar',
                valor: resumen.creditosPendientes.toDouble(),
                color: Dash.sky,
                sufijo: ' cr',
                pie: 'para completar el plan',
              ),
              _Cifra(
                etiqueta: 'Cursos aprobados',
                valor: resumen.cursosAprobados.toDouble(),
                color: Dash.aqua,
                pie: 'de ${resumen.cursosTotal} cursos',
              ),
              _Cifra(
                etiqueta: 'Requisitos cumplidos',
                valor: requisitos.cumplidos.toDouble(),
                color: Dash.amber,
                pie: 'de ${requisitos.total} validados',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ultimoAvance(_cursoMasReciente(datos.avance.cursos)),
        ],
      ),
    );
  }

  /// Panel con el curso aprobado más reciente de la malla.
  Widget _ultimoAvance(CursoProgreso? curso) {
    if (curso == null) return const SizedBox.shrink();
    final fecha = curso.fechaAprobacion!;
    final nota = curso.nota == null
        ? 'sin nota registrada'
        : 'nota ${_porcentaje1(curso.nota!)}';
    return GlassPanel(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const Icon(
            Icons.workspace_premium_outlined,
            color: Dash.amber,
            size: 30,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Último avance registrado',
                  style: Dash.body(
                    12.5,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${curso.nombre} · ${fechaCorta(fecha)}',
                  style: Dash.body(15, weight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${curso.codigo} · $nota',
                  style: Dash.code(12.5, color: Dash.sky),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- niveles

  Widget _niveles(_DatosInicio datos) {
    final niveles = datos.avance.niveles;
    return Reveal(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            titulo: 'Niveles del plan',
            subtitulo:
                'Del nivel I al último: plan ${datos.avance.plan}, '
                '${niveles.length} tramos hasta el grado.',
          ),
          const SizedBox(height: 16),
          GlassPanel(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Column(
              children: [for (final nivel in niveles) _Nivel(nivel: nivel)],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- logros

  Widget _logros(_DatosInicio datos) {
    final cumplidos = datos.requisitos
        .where((requisito) => requisito.estado == EstadoRequisito.cumplido)
        .toList();
    final enProceso = datos.requisitos
        .where((requisito) => requisito.estado == EstadoRequisito.enProceso)
        .length;
    final total = datos.resumenRequisitos.total;
    final visibles = cumplidos.take(6).toList();
    final restantes = cumplidos.length - visibles.length;

    return Reveal(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            titulo: 'Logros de grado',
            subtitulo: cumplidos.isEmpty
                ? 'Todavía no tienes requisitos validados; empieza por los '
                      'que ya estás tramitando.'
                : '${cumplidos.length} de $total requisitos validados por '
                      'coordinación académica.',
          ),
          const SizedBox(height: 16),
          if (cumplidos.isEmpty)
            GlassPanel(
              child: Row(
                children: [
                  const Icon(
                    Icons.emoji_events_outlined,
                    color: Dash.amber,
                    size: 30,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Tu primer sello está más cerca de lo que crees: '
                      'revisa la pestaña Requisitos.',
                      style: Dash.body(14),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            GlassPanel(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  for (var i = 0; i < visibles.length; i++) ...[
                    if (i > 0) const Divider(height: 18, color: Colors.white12),
                    _Logro(requisito: visibles[i]),
                  ],
                ],
              ),
            ),
            if (restantes > 0) ...[
              const SizedBox(height: 10),
              Text(
                '+$restantes requisitos más cumplidos.',
                style: Dash.body(13, color: Dash.sky),
              ),
            ],
          ],
          if (enProceso > 0) ...[
            const SizedBox(height: 12),
            Text(
              '$enProceso requisito${enProceso == 1 ? '' : 's'} en proceso.',
              style: Dash.body(13, color: Dash.amber),
            ),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ cierre

  Widget _cierre(_DatosInicio datos) {
    return Reveal(
      child: Column(
        children: [
          const SizedBox(height: 4),
          Image.asset(
            DashAssets.siluetas,
            height: 120,
            width: double.infinity,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox(height: 120),
          ),
          const SizedBox(height: 12),
          Text(
            'Cada crédito te acerca a cruzar ese escenario.',
            textAlign: TextAlign.center,
            style: Dash.body(14.5, weight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Plan ${datos.avance.plan} · periodo ${datos.avance.periodoActual}',
            textAlign: TextAlign.center,
            style: Dash.code(12.5, color: Dash.sky),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

/// Número con un decimal y coma decimal (el mismo formato del astrolabio).
String _porcentaje1(double valor) =>
    valor.toStringAsFixed(1).replaceAll('.', ',');

/// Curso aprobado con la fecha de aprobación más reciente.
CursoProgreso? _cursoMasReciente(List<CursoProgreso> cursos) {
  CursoProgreso? mejor;
  DateTime? mejorFecha;
  for (final curso in cursos) {
    final fecha = curso.fechaAprobacion;
    if (!curso.aprobado || fecha == null) continue;
    if (mejorFecha == null || fecha.isAfter(mejorFecha)) {
      mejor = curso;
      mejorFecha = fecha;
    }
  }
  return mejor;
}

/// Número romano para los niveles del plan (I, II, III…).
String _romano(int valor) {
  const cifras = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];
  const letras = [
    'M',
    'CM',
    'D',
    'CD',
    'C',
    'XC',
    'L',
    'XL',
    'X',
    'IX',
    'V',
    'IV',
    'I',
  ];
  var resto = valor;
  final texto = StringBuffer();
  for (var i = 0; i < cifras.length; i++) {
    while (resto >= cifras[i]) {
      texto.write(letras[i]);
      resto -= cifras[i];
    }
  }
  return texto.toString();
}

/// Tarjeta de una cifra del avance, con el contador animado.
class _Cifra extends StatelessWidget {
  const _Cifra({
    required this.etiqueta,
    required this.valor,
    required this.color,
    this.sufijo = '',
    this.pie,
  });

  final String etiqueta;
  final double valor;
  final Color color;
  final String sufijo;
  final String? pie;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      blur: false,
      alpha: 0.34,
      radius: 22,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            etiqueta,
            style: Dash.body(12.5, color: Colors.white.withValues(alpha: 0.75)),
          ),
          const SizedBox(height: 8),
          AnimatedCounter(
            value: valor,
            style: Dash.code(32, color: color),
            suffix: sufijo,
          ),
          if (pie != null) ...[
            const SizedBox(height: 6),
            Text(pie!, style: Dash.body(12, color: Dash.sky)),
          ],
        ],
      ),
    );
  }
}

/// Barra de avance de un nivel del plan.
class _Nivel extends StatelessWidget {
  const _Nivel({required this.nivel});

  final NivelProgreso nivel;

  @override
  Widget build(BuildContext context) {
    final completo = nivel.porcentaje >= 100;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            child: Text(
              _romano(nivel.nivel),
              style: Dash.code(14, color: Dash.sky),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: nivel.porcentaje / 100),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (context, valor, _) => LinearProgressIndicator(
                  value: valor,
                  minHeight: 12,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    completo ? Dash.aqua : Dash.amber,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 92,
            child: Text(
              '${nivel.creditosAprobados}/${nivel.creditosTotales} cr',
              textAlign: TextAlign.end,
              style: Dash.code(12.5),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 52,
            child: Text(
              '${nivel.porcentaje.toStringAsFixed(0)} %',
              textAlign: TextAlign.end,
              style: Dash.code(12.5, color: completo ? Dash.aqua : Dash.amber),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila de requisito cumplido con su sello ✕.
class _Logro extends StatelessWidget {
  const _Logro({required this.requisito});

  final Requisito requisito;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SelloX(size: 34),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                requisito.nombre,
                style: Dash.body(14.5, weight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                'Validado por coordinación',
                style: Dash.body(11.5, color: Dash.sky),
              ),
            ],
          ),
        ),
        const Icon(Icons.verified_rounded, color: Dash.aqua, size: 22),
      ],
    );
  }
}
