import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/curriculo/models.dart';
import 'malla_areas.dart';

/// Medidas fijas del tablero. Al ser constantes, cada curso queda en una
/// posición calculable y los conectores de prerrequisitos se pueden dibujar
/// exactamente entre un nodo y otro.
const double _anchoColumna = 208;
const double _huecoColumna = 16;
const double _altoCabecera = 54;
const double _altoNodo = 130;
const double _huecoNodo = 14;
const double _margen = 14;
const double _bajoCabecera = 10;

double _yNodo(int slot) =>
    _margen + _altoCabecera + _bajoCabecera + slot * (_altoNodo + _huecoNodo);

/// Permite mover el tablero desde fuera: los botones de zoom, la ficha de un
/// curso y el enfoque automático al nivel del estudiante.
class TableroMalla {
  TransformationController? _control;
  AnimationController? _vuelo;
  Matrix4Tween? _tween;
  Size _viewport = Size.zero;
  Size _contenido = Size.zero;
  Map<String, Rect> _posiciones = const <String, Rect>{};
  Map<int, Rect> _columnas = const <int, Rect>{};

  /// Se llama en cada construcción del tablero para mantener posiciones,
  /// tamaño de pantalla y controlador siempre actualizados.
  void adjuntar({
    required TransformationController control,
    required TickerProvider vsync,
    required Size viewport,
    required Size contenido,
    required Map<String, Rect> posiciones,
    required Map<int, Rect> columnas,
  }) {
    _control = control;
    _vuelo ??= AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 700),
    )..addListener(_aplicar);
    _viewport = viewport;
    _contenido = contenido;
    _posiciones = posiciones;
    _columnas = columnas;
  }

  /// Libera el controlador creado por [adjuntar]. Puede llamarse más de una
  /// vez: el tablero y la pantalla que lo contiene se desmontan en orden
  /// distinto según el recorrido del árbol.
  void dispose() => desadjuntar();

  void desadjuntar() {
    _vuelo?.dispose();
    _vuelo = null;
    _control = null;
    _tween = null;
    _viewport = Size.zero;
    _contenido = Size.zero;
    _posiciones = const <String, Rect>{};
    _columnas = const <int, Rect>{};
  }

  bool get _listo =>
      _control != null &&
      _vuelo != null &&
      _viewport.width > 0 &&
      _viewport.height > 0 &&
      _contenido.width > 0;

  void _aplicar() {
    final control = _control;
    final vuelo = _vuelo;
    final tween = _tween;
    if (control == null || vuelo == null || tween == null) return;
    control.value = tween.evaluate(vuelo);
  }

  void _irA(Matrix4 destino) {
    if (!_listo) return;
    final control = _control!;
    final vuelo = _vuelo!;
    _tween = Matrix4Tween(begin: control.value, end: destino);
    vuelo.forward(from: 0);
  }

  Matrix4 _matriz(double escala, double tx, double ty) => Matrix4.identity()
    ..setEntry(0, 0, escala)
    ..setEntry(1, 1, escala)
    ..setEntry(0, 3, tx)
    ..setEntry(1, 3, ty);

  /// Escala manteniendo el centro de la pantalla como eje.
  void _zoom(double factor) {
    if (!_listo) return;
    final actual = _control!.value;
    final escala = actual.getMaxScaleOnAxis();
    final nueva = (escala * factor).clamp(0.4, 2.4).toDouble();
    final cx = _viewport.width / 2;
    final cy = _viewport.height / 2;
    final traslacion = actual.getTranslation();
    final px = (cx - traslacion.x) / escala;
    final py = (cy - traslacion.y) / escala;
    _irA(_matriz(nueva, cx - px * nueva, cy - py * nueva));
  }

  void acercar() => _zoom(1.3);

  void alejar() => _zoom(1 / 1.3);

  /// Ajusta el tablero completo dentro de la pantalla.
  void ajustar() {
    if (!_listo) return;
    final escala = math
        .min(
          _viewport.width / _contenido.width,
          _viewport.height / _contenido.height,
        )
        .clamp(0.4, 1.0)
        .toDouble();
    final tx = (_viewport.width - _contenido.width * escala) / 2;
    final ty = (_viewport.height - _contenido.height * escala) / 2;
    _irA(_matriz(escala, tx, ty));
  }

  /// Centra un curso en la pantalla (lo usa la ficha de detalles).
  void irA(String codigo) {
    if (!_listo) return;
    final rect = _posiciones[codigo];
    if (rect == null) return;
    final escala = math.max(_control!.value.getMaxScaleOnAxis(), 1.0);
    final tx = _viewport.width / 2 - rect.center.dx * escala;
    final ty = _viewport.height / 2 - rect.center.dy * escala;
    _irA(_matriz(escala, tx, ty));
  }

  /// Centra la columna de un nivel (lo usa el enfoque automático).
  void irANivel(int nivel) {
    if (!_listo) return;
    final rect = _columnas[nivel];
    if (rect == null) return;
    final escala = math.max(_control!.value.getMaxScaleOnAxis(), 0.85);
    final tx = _viewport.width / 2 - rect.center.dx * escala;
    final ty = _viewport.height / 2 - rect.center.dy * escala;
    _irA(_matriz(escala, tx, ty));
  }
}

/// Tablero desplazable y ampliable con los diez niveles de la malla.
class MallaTablero extends StatefulWidget {
  const MallaTablero({
    super.key,
    required this.niveles,
    required this.cursosPorNivel,
    required this.semestreActual,
    required this.seleccion,
    required this.areaActiva,
    required this.control,
    required this.onSeleccionar,
    required this.onLimpiar,
  });

  final List<int> niveles;
  final Map<int, List<CursoCurricular>> cursosPorNivel;
  final int? semestreActual;
  final String? seleccion;
  final String? areaActiva;
  final TableroMalla control;
  final void Function(CursoCurricular curso) onSeleccionar;
  final VoidCallback onLimpiar;

  @override
  State<MallaTablero> createState() => _MallaTableroState();
}

class _MallaTableroState extends State<MallaTablero>
    with TickerProviderStateMixin {
  final TransformationController _transformacion = TransformationController();

  late final AnimationController _entrada = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  /// Late porque la pulsación de "estás aquí" solo corre si hay animaciones.
  late final AnimationController _pulso = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  late final AnimationController _conectores = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  Timer? _enfoque;
  bool _enfocado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_enfocado) return;
    _enfocado = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrada.value = 1;
      _pulso.value = 0.5;
      _enfocarNivel();
    } else {
      _entrada.forward();
      _pulso.repeat(reverse: true);
      _enfoque = Timer(const Duration(milliseconds: 1500), _enfocarNivel);
    }
  }

  void _enfocarNivel() {
    final nivel = widget.semestreActual;
    if (nivel == null || !mounted) return;
    widget.control.irANivel(nivel);
  }

  @override
  void dispose() {
    _enfoque?.cancel();
    _entrada.dispose();
    _pulso.dispose();
    _conectores.dispose();
    _transformacion.dispose();
    widget.control.desadjuntar();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MallaTablero viejo) {
    super.didUpdateWidget(viejo);
    if (viejo.seleccion != widget.seleccion) {
      if (widget.seleccion == null) {
        _conectores.reverse();
      } else {
        _conectores.forward(from: 0);
      }
    }
  }

  /// Recorre el grafo de prerrequisitos hacia atrás (lo que hay que tener
  /// aprobado) y hacia adelante (lo que este curso desbloquea).
  ({Set<String> ruta, Set<String> destinos}) _calcularRutas(String? codigo) {
    final ruta = <String>{};
    final destinos = <String>{};
    if (codigo == null) return (ruta: ruta, destinos: destinos);

    final porCodigo = <String, CursoCurricular>{};
    for (final lista in widget.cursosPorNivel.values) {
      for (final curso in lista) {
        porCodigo[curso.codigo] = curso;
      }
    }

    final pendientes = <String>[codigo];
    while (pendientes.isNotEmpty) {
      final actual = pendientes.removeLast();
      final curso = porCodigo[actual];
      if (curso == null) continue;
      for (final pre in curso.prerequisitos) {
        if (ruta.add(pre)) pendientes.add(pre);
      }
    }
    ruta.remove(codigo);

    for (final curso in porCodigo.values) {
      if (curso.codigo != codigo && curso.prerequisitos.contains(codigo)) {
        destinos.add(curso.codigo);
      }
    }
    return (ruta: ruta, destinos: destinos);
  }

  double _retraso(int columna, int slot) {
    final total = math.max(widget.niveles.length, 1);
    final base = columna / total * 0.55 + slot * 0.03;
    return base.clamp(0.0, 0.88).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final niveles = widget.niveles;
    final maxCursos = niveles.fold<int>(
      0,
      (mayor, nivel) =>
          math.max(mayor, widget.cursosPorNivel[nivel]?.length ?? 0),
    );
    final ancho =
        _margen * 2 +
        niveles.length * (_anchoColumna + _huecoColumna) -
        _huecoColumna;
    final alto =
        _margen * 2 +
        _altoCabecera +
        _bajoCabecera +
        math.max(maxCursos, 1) * (_altoNodo + _huecoNodo) -
        _huecoNodo;

    // Posiciones exactas: sirven para colocar los nodos y dibujar los
    // conectores de prerrequisitos en el mismo sistema de coordenadas.
    final posiciones = <String, Rect>{};
    final columnas = <int, Rect>{};
    for (var i = 0; i < niveles.length; i++) {
      final nivel = niveles[i];
      final x = _margen + i * (_anchoColumna + _huecoColumna);
      columnas[nivel] = Rect.fromLTWH(x, _margen, _anchoColumna, alto);
      final cursos = widget.cursosPorNivel[nivel] ?? const <CursoCurricular>[];
      for (var slot = 0; slot < cursos.length; slot++) {
        posiciones[cursos[slot].codigo] = Rect.fromLTWH(
          x,
          _yNodo(slot),
          _anchoColumna,
          _altoNodo,
        );
      }
    }

    final seleccion = widget.seleccion;
    final rutas = _calcularRutas(seleccion);
    final conectores = <(Rect, Rect, Color)>[];
    if (seleccion != null) {
      final origen = posiciones[seleccion];
      if (origen != null) {
        for (final codigo in rutas.ruta) {
          final desde = posiciones[codigo];
          if (desde == null) continue;
          conectores.add((desde, origen, MallaAreas.deCodigo(codigo).color));
        }
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Encabezado(
              niveles: niveles.length,
              seleccion: seleccion,
              semestreActual: widget.semestreActual,
              onAcercar: widget.control.acercar,
              onAlejar: widget.control.alejar,
              onAjustar: widget.control.ajustar,
              onTuNivel: _enfocarNivel,
              onLimpiar: widget.onLimpiar,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (context, limites) {
                  final viewport = Size(limites.maxWidth, limites.maxHeight);
                  widget.control.adjuntar(
                    control: _transformacion,
                    vsync: this,
                    viewport: viewport,
                    contenido: Size(ancho, alto),
                    posiciones: posiciones,
                    columnas: columnas,
                  );
                  return SizedBox(
                    height: limites.maxHeight,
                    child: InteractiveViewer(
                      transformationController: _transformacion,
                      constrained: false,
                      clipBehavior: Clip.hardEdge,
                      boundaryMargin: const EdgeInsets.all(24),
                      minScale: 0.4,
                      maxScale: 2.4,
                      child: SizedBox(
                        width: ancho,
                        height: alto,
                        child: Stack(
                          children: [
                            for (var i = 0; i < niveles.length; i++) ...[
                              _Carril(
                                x:
                                    _margen +
                                    i * (_anchoColumna + _huecoColumna),
                                alto: alto,
                                esActual: niveles[i] == widget.semestreActual,
                                animacion: _entrada,
                                retraso: _retraso(i, 0),
                              ),
                            ],
                            Positioned.fill(
                              child: RepaintBoundary(
                                child: CustomPaint(
                                  painter: _PintorConectores(
                                    conectores,
                                    _conectores.value,
                                  ),
                                ),
                              ),
                            ),
                            for (var i = 0; i < niveles.length; i++) ...[
                              _CabeceraNivel(
                                x:
                                    _margen +
                                    i * (_anchoColumna + _huecoColumna),
                                nivel: niveles[i],
                                cantidad:
                                    widget.cursosPorNivel[niveles[i]]?.length ??
                                    0,
                                esActual: niveles[i] == widget.semestreActual,
                                animacion: _entrada,
                                retraso: _retraso(i, 0),
                                pulso: _pulso,
                              ),
                              for (
                                var slot = 0;
                                slot <
                                    (widget
                                            .cursosPorNivel[niveles[i]]
                                            ?.length ??
                                        0);
                                slot++
                              ) ...[
                                _nodo(
                                  curso:
                                      widget.cursosPorNivel[niveles[i]]![slot],
                                  x:
                                      _margen +
                                      i * (_anchoColumna + _huecoColumna),
                                  y: _yNodo(slot),
                                  retraso: _retraso(i, slot + 1),
                                  seleccion: seleccion,
                                  ruta: rutas.ruta,
                                  destinos: rutas.destinos,
                                  areaActiva: widget.areaActiva,
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nodo({
    required CursoCurricular curso,
    required double x,
    required double y,
    required double retraso,
    required String? seleccion,
    required Set<String> ruta,
    required Set<String> destinos,
    required String? areaActiva,
  }) {
    final area = MallaAreas.deCodigo(curso.codigo);
    final esSeleccion = curso.codigo == seleccion;
    final enRuta = ruta.contains(curso.codigo);
    final esDestino = destinos.contains(curso.codigo);

    var opacidad = 1.0;
    if (areaActiva != null && area.id != areaActiva) opacidad = 0.2;
    if (seleccion != null && !esSeleccion && !enRuta && !esDestino) {
      opacidad = math.min(opacidad, 0.28);
    }

    final borde = esSeleccion
        ? AppColors.gold
        : enRuta
        ? area.color
        : esDestino
        ? area.color.withValues(alpha: 0.55)
        : AppColors.border;
    final grosor = esSeleccion ? 2.5 : (enRuta ? 2.0 : 1.0);

    return Positioned(
      left: x,
      top: y,
      width: _anchoColumna,
      height: _altoNodo,
      child: _Aparece(
        animacion: _entrada,
        retraso: retraso,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 320),
          opacity: opacidad,
          child: AnimatedScale(
            scale: esSeleccion ? 1.03 : 1,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutBack,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => widget.onSeleccionar(curso),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borde, width: grosor),
                    boxShadow: [
                      if (esSeleccion)
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.35),
                          blurRadius: 18,
                          spreadRadius: 1,
                        )
                      else
                        BoxShadow(
                          color: const Color(
                            0xFF0F172A,
                          ).withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: area.tinte,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Text(
                              curso.codigo,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                                color: area.texto,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: area.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Text(
                              '${curso.creditos} cr',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: area.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        curso.nombre,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                          height: 1.18,
                        ),
                      ),
                      const Spacer(),
                      _PiePrerrequisitos(curso: curso, area: area),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pie del nodo: qué se necesita para tomar el curso. Se muestran los dos
/// primeros códigos y el resto como contador, para no ensanchar la tarjeta.
class _PiePrerrequisitos extends StatelessWidget {
  const _PiePrerrequisitos({required this.curso, required this.area});

  final CursoCurricular curso;
  final MallaArea area;

  @override
  Widget build(BuildContext context) {
    final prerrequisitos = curso.prerequisitos;
    if (prerrequisitos.isEmpty) {
      return const Text(
        'Sin prerrequisitos',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
        ),
      );
    }
    final visibles = prerrequisitos.take(2).toList();
    final resto = prerrequisitos.length - visibles.length;
    return Row(
      children: [
        const Icon(Icons.link_rounded, size: 11, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Expanded(
          child: Wrap(
            spacing: 4,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final codigo in visibles)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLow,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    codigo,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              if (resto > 0)
                Text(
                  '+$resto',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: area.color,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Fondo tenue detrás de cada columna de nivel.
class _Carril extends StatelessWidget {
  const _Carril({
    required this.x,
    required this.alto,
    required this.esActual,
    required this.animacion,
    required this.retraso,
  });

  final double x;
  final double alto;
  final bool esActual;
  final Animation<double> animacion;
  final double retraso;

  @override
  Widget build(BuildContext context) => Positioned(
    left: x - 6,
    top: _margen - 6,
    width: _anchoColumna + 12,
    height: alto,
    child: _Aparece(
      animacion: animacion,
      retraso: retraso,
      child: Container(
        decoration: BoxDecoration(
          color: esActual
              ? const Color(0xFFFFF7E6)
              : AppColors.surfaceLow.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
          border: esActual
              ? Border.all(color: AppColors.gold.withValues(alpha: 0.35))
              : null,
        ),
      ),
    ),
  );
}

/// Encabezado de cada nivel con su número en romanos.
class _CabeceraNivel extends StatelessWidget {
  const _CabeceraNivel({
    required this.x,
    required this.nivel,
    required this.cantidad,
    required this.esActual,
    required this.animacion,
    required this.retraso,
    required this.pulso,
  });

  final double x;
  final int nivel;
  final int cantidad;
  final bool esActual;
  final Animation<double> animacion;
  final double retraso;
  final Animation<double> pulso;

  @override
  Widget build(BuildContext context) => Positioned(
    left: x,
    top: _margen,
    width: _anchoColumna,
    height: _altoCabecera,
    child: _Aparece(
      animacion: animacion,
      retraso: retraso,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: esActual
                ? const [Color(0xFFF59E0B), Color(0xFFFBBF24)]
                : const [AppColors.navy, Color(0xFF1E3A8A)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            if (esActual)
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
          ],
        ),
        child: Row(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NIVEL',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                    color: esActual
                        ? AppColors.navy.withValues(alpha: 0.7)
                        : Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  MallaAreas.romano(nivel),
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    color: esActual ? AppColors.navy : Colors.white,
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (esActual)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: pulso,
                    builder: (context, child) => Opacity(
                      opacity: 0.35 + 0.65 * pulso.value,
                      child: child,
                    ),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.navy,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'AQUÍ',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              )
            else
              Text(
                '$cantidad cursos',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// Barra superior del tablero: título, estado de la ruta y controles.
class _Encabezado extends StatelessWidget {
  const _Encabezado({
    required this.niveles,
    required this.seleccion,
    required this.semestreActual,
    required this.onAcercar,
    required this.onAlejar,
    required this.onAjustar,
    required this.onTuNivel,
    required this.onLimpiar,
  });

  final int niveles;
  final String? seleccion;
  final int? semestreActual;
  final VoidCallback onAcercar;
  final VoidCallback onAlejar;
  final VoidCallback onAjustar;
  final VoidCallback onTuNivel;
  final VoidCallback onLimpiar;

  @override
  Widget build(BuildContext context) {
    final hayRuta = seleccion != null;

    final titulo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Ruta de la malla',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Arrastra para moverte · pellizca o usa los botones para acercar',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );

    final controles = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hayRuta) ...[
          _BotonTablero(
            etiqueta: 'Limpiar ruta',
            icono: Icons.close_rounded,
            tono: AppColors.gold,
            onPressed: onLimpiar,
          ),
          const SizedBox(width: 6),
        ],
        if (semestreActual != null) ...[
          _BotonTablero(
            etiqueta: 'Tu nivel',
            icono: Icons.my_location_rounded,
            tono: AppColors.cyan,
            onPressed: onTuNivel,
          ),
          const SizedBox(width: 6),
        ],
        _BotonTablero(
          icono: Icons.remove_rounded,
          onPressed: onAlejar,
          etiqueta: 'Alejar',
        ),
        const SizedBox(width: 6),
        _BotonTablero(
          icono: Icons.add_rounded,
          onPressed: onAcercar,
          etiqueta: 'Acercar',
        ),
        const SizedBox(width: 6),
        _BotonTablero(
          icono: Icons.fit_screen_rounded,
          onPressed: onAjustar,
          etiqueta: 'Ajustar',
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, limites) {
        // En pantallas angostas los controles bajan a su propia fila para
        // que el título no quede aplastado.
        if (limites.maxWidth < 560) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [titulo, const SizedBox(height: 10), controles],
          );
        }
        return Row(
          children: [
            Expanded(child: titulo),
            const SizedBox(width: 12),
            controles,
          ],
        );
      },
    );
  }
}

class _BotonTablero extends StatelessWidget {
  const _BotonTablero({
    required this.icono,
    required this.onPressed,
    required this.etiqueta,
    this.tono,
  });

  final IconData icono;
  final VoidCallback onPressed;
  final String etiqueta;
  final Color? tono;

  @override
  Widget build(BuildContext context) {
    final color = tono ?? AppColors.navy;
    return Tooltip(
      message: etiqueta,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: tono == null ? AppColors.surfaceLow : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: tono == null
                  ? AppColors.border
                  : color.withValues(alpha: 0.4),
            ),
          ),
          child: Icon(icono, size: 17, color: color),
        ),
      ),
    );
  }
}

/// Entrada escalonada de los elementos del tablero: fundido + desplazamiento.
class _Aparece extends StatelessWidget {
  const _Aparece({
    required this.animacion,
    required this.retraso,
    required this.child,
  });

  final Animation<double> animacion;
  final double retraso;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curva = Interval(
      retraso,
      (retraso + 0.4).clamp(retraso + 0.04, 1.0).toDouble(),
      curve: Curves.easeOutCubic,
    );
    return AnimatedBuilder(
      animation: animacion,
      child: child,
      builder: (context, contenido) {
        final v = curva.transform(animacion.value);
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, (1 - v) * 18),
            child: contenido,
          ),
        );
      },
    );
  }
}

/// Dibuja las curvas entre un prerrequisito y el curso seleccionado.
class _PintorConectores extends CustomPainter {
  const _PintorConectores(this.conectores, this.avance);

  final List<(Rect, Rect, Color)> conectores;
  final double avance;

  @override
  void paint(Canvas canvas, Size size) {
    if (avance <= 0 || conectores.isEmpty) return;
    for (final conexion in conectores) {
      final desde = conexion.$1;
      final hasta = conexion.$2;
      final color = conexion.$3;

      final inicio = Offset(desde.center.dx, desde.bottom - 4);
      final fin = Offset(hasta.center.dx, hasta.top + 4);
      final dy = fin.dy - inicio.dy;
      final trayectoria = Path()
        ..moveTo(inicio.dx, inicio.dy)
        ..cubicTo(
          inicio.dx,
          inicio.dy + dy * 0.5,
          fin.dx,
          fin.dy - dy * 0.5,
          fin.dx,
          fin.dy,
        );

      canvas.drawPath(
        trayectoria,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: 0.14 * avance),
      );
      canvas.drawPath(
        trayectoria,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: 0.85 * avance),
      );
      canvas.drawCircle(
        inicio,
        3.2 * avance,
        Paint()..color = color.withValues(alpha: 0.6 * avance),
      );
      canvas.drawCircle(
        fin,
        3.6 * avance,
        Paint()..color = color.withValues(alpha: 0.95 * avance),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PintorConectores viejo) =>
      viejo.avance != avance || viejo.conectores != conectores;
}
