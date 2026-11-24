import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/widgets/async_view.dart';
import 'package:frontend/core/widgets/page_list.dart';
import 'malla_service.dart';
import 'models.dart';
import 'widgets/malla_areas.dart';
import 'widgets/malla_tablero.dart';

/// Pantalla de la malla curricular.
///
/// Se organiza en tres franjas: un encabezado con la mascota de la
/// promoción, la leyenda de áreas que sirve de filtro y el tablero
/// interactivo donde se traza la ruta de prerrequisitos de un curso.
class MallaScreen extends StatefulWidget {
  const MallaScreen({
    super.key,
    required this.service,
    required this.programa,
    this.semestreActual,
  });

  final MallaService service;
  final String programa;
  final int? semestreActual;

  @override
  State<MallaScreen> createState() => _MallaScreenState();
}

class _MallaScreenState extends State<MallaScreen> {
  /// Controlador compartido con el tablero: permite centrar la vista desde
  /// los botones y desde la ficha de un curso.
  final TableroMalla _tablero = TableroMalla();

  /// Código del curso cuya ruta está iluminada.
  String? _seleccion;

  /// Área curricular filtrada; `null` muestra todas.
  String? _area;

  /// Copia vigente de los cursos por código, para resolver los saltos de la
  /// ficha sin volver a consultar el servicio.
  Map<String, CursoCurricular> _porCodigo = const <String, CursoCurricular>{};

  @override
  void dispose() {
    _tablero.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _FondoMalla(
    child: AsyncView<MallaCurricular>(
      load: () => widget.service.obtener(widget.programa),
      builder: (context, malla) {
        final cursosPorNivel = <int, List<CursoCurricular>>{};
        for (final curso in malla.cursos) {
          cursosPorNivel.putIfAbsent(curso.nivel, () => []).add(curso);
        }
        for (final cursos in cursosPorNivel.values) {
          cursos.sort((a, b) => a.nombre.compareTo(b.nombre));
        }
        final niveles = cursosPorNivel.keys.toList()..sort();
        _porCodigo = <String, CursoCurricular>{
          for (final curso in malla.cursos) curso.codigo: curso,
        };

        // El tablero vive dentro de una lista, así que necesita una altura
        // explícita: la tomo de la pantalla para que siempre quepa espacio
        // para arrastrar en vertical sin tapar la leyenda ni el consejo.
        final altoTablero = (MediaQuery.sizeOf(context).height * 0.55)
            .clamp(380.0, 560.0)
            .toDouble();

        return PageList(
          maxWidth: 1180,
          children: [
            _HeroMalla(malla: malla),
            const SizedBox(height: 14),
            _LeyendaAreas(
              malla: malla,
              areaActiva: _area,
              onCambiar: (id) => setState(() {
                _area = id == null ? null : (_area == id ? null : id);
              }),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: altoTablero,
              child: MallaTablero(
                niveles: niveles,
                cursosPorNivel: cursosPorNivel,
                semestreActual: widget.semestreActual,
                seleccion: _seleccion,
                areaActiva: _area,
                control: _tablero,
                onSeleccionar: (curso) {
                  setState(() => _seleccion = curso.codigo);
                  _abrirFicha(curso);
                },
                onLimpiar: () => setState(() => _seleccion = null),
              ),
            ),
            const SizedBox(height: 14),
            const _ConsejoRuta(),
          ],
        );
      },
    ),
  );

  /// Abre la ficha del curso. Si desde la ficha se salta a un prerrequisito
  /// o a un curso desbloqueado, la ficha se sustituye por la del curso de
  /// destino y la ruta del tablero se recalcula.
  Future<void> _abrirFicha(CursoCurricular curso) async {
    final destino = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FichaCurso(
        curso: curso,
        porCodigo: _porCodigo,
        dependientes: [
          for (final otro in _porCodigo.values)
            if (otro.prerequisitos.contains(curso.codigo)) otro,
        ],
        control: _tablero,
      ),
    );
    if (!mounted) return;

    // Ficha cerrada sin salto: se apaga la ruta.
    if (destino == null) {
      setState(() => _seleccion = null);
      return;
    }

    final salto = _porCodigo[destino];
    if (salto == null) return;
    // «Centrar en el tablero» devuelve el propio curso: se mantiene la ruta
    // encendida sin reabrir la ficha.
    if (salto.codigo == curso.codigo) return;

    setState(() => _seleccion = salto.codigo);
    await _abrirFicha(salto);
  }
}

// ---------------------------------------------------------------------------
// Fondo de la página
// ---------------------------------------------------------------------------

/// Pinta el fondo con el morado de la bienvenida y lo va aclarando hasta
/// blanco a medida que se baja. Vive en su propio estado para que el
/// desplazamiento no reconstruya la malla completa.
class _FondoMalla extends StatefulWidget {
  const _FondoMalla({required this.child});

  final Widget child;

  @override
  State<_FondoMalla> createState() => _FondoMallaState();
}

class _FondoMallaState extends State<_FondoMalla> {
  /// Avance del desplazamiento (0 arriba, 1 al fondo), redondeado al 1 %
  /// para no reconstruir en cada píxel.
  double _avance = 0;

  static const _moradoAlto = Color(0xFF3A0090);
  static const _moradoBajo = Color(0xFF6A00D8);

  bool _alDesplazar(ScrollNotification notificacion) {
    // Solo el desplazamiento vertical de la lista principal: la leyenda
    // horizontal y el tablero no deben cambiar el tono del fondo.
    if (notificacion.depth != 0 || notificacion.metrics.axis != Axis.vertical) {
      return false;
    }
    final recorrido = notificacion.metrics.maxScrollExtent;
    final bruto = recorrido <= 0
        ? 0.0
        : notificacion.metrics.pixels / recorrido;
    final avance = (bruto.clamp(0.0, 1.0) * 100).round() / 100;
    if (avance != _avance) {
      setState(() => _avance = avance);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollNotification>(
        onNotification: _alDesplazar,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(_moradoAlto, const Color(0xFFEDE4FF), _avance)!,
                Color.lerp(_moradoBajo, Colors.white, _avance)!,
              ],
            ),
          ),
          child: widget.child,
        ),
      );
}

// ---------------------------------------------------------------------------
// Encabezado
// ---------------------------------------------------------------------------

class _HeroMalla extends StatefulWidget {
  const _HeroMalla({required this.malla});

  final MallaCurricular malla;

  @override
  State<_HeroMalla> createState() => _HeroMallaState();
}

class _HeroMallaState extends State<_HeroMalla> with TickerProviderStateMixin {
  /// Va y viene suave de la mascota.
  late final AnimationController _flota = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat(reverse: true);

  /// Destello de las chispas de graduación.
  late final AnimationController _chispas = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  )..repeat(reverse: true);

  /// Aurora rosada en bucle del recuadro del título.
  late final AnimationController _aurora = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 7000),
  )..repeat();

  @override
  void dispose() {
    _flota.dispose();
    _chispas.dispose();
    _aurora.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final malla = widget.malla;
    final compacto = MediaQuery.sizeOf(context).width < 640;

    // Recuadro del título: media pantalla, letras blancas sobre negro y
    // una aurora de tonos rosaceos y morados en bucle.
    final caja = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDB2777).withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          Positioned.fill(child: _Aurora(control: _aurora)),
          Padding(
            padding: EdgeInsets.fromLTRB(
              compacto ? 16 : 24,
              compacto ? 16 : 20,
              compacto ? 16 : 24,
              compacto ? 14 : 16,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _Etiqueta(
                          icono: Icons.school_rounded,
                          texto: malla.programa,
                          tono: const Color(0xFF7DD3FC),
                        ),
                        _Etiqueta(
                          icono: Icons.assignment_turned_in_rounded,
                          texto: 'Plan ${malla.plan}',
                          tono: AppColors.gold,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Escala hacia abajo si hace falta: el título nunca
                    // desborda el medio ancho del recuadro.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Malla curricular',
                        style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: compacto ? 28 : 42,
                          fontWeight: FontWeight.w800,
                          height: 1.03,
                          letterSpacing: -0.8,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      compacto
                          ? 'Arrastra, amplía y toca un curso para trazar su ruta.'
                          : 'Mueve el tablero con el dedo o el mouse y toca cualquier curso para iluminar tu ruta.',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: compacto ? 12.5 : 13.5,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Dato(
                      valor: '${malla.niveles}',
                      etiqueta: 'niveles',
                      icono: Icons.view_week_rounded,
                    ),
                    _Dato(
                      valor: '${malla.cursos.length}',
                      etiqueta: 'cursos',
                      icono: Icons.menu_book_rounded,
                    ),
                    _Dato(
                      valor: '${malla.creditosTotales}',
                      etiqueta: 'créditos',
                      icono: Icons.bolt_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // Texto debajo del recuadro: enlaza el título con el resto de la
    // página, del lado izquierdo.
    final pie = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: compacto ? 300 : 360),
      child: Text(
        compacto
            ? 'Toca un curso y su ruta se ilumina.'
            : 'Cada curso encadena su ruta: toca uno y verás qué necesitas aprobar y qué desbloquea.',
        textAlign: TextAlign.left,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: compacto ? 12 : 13,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
    );

    // Altura del encabezado: lo justo para que el muñequito llene la
    // mitad derecha entera sin pisar la leyenda ni el tablero de abajo.
    final anchoUtil = math.min(MediaQuery.sizeOf(context).width - 48, 1180);
    final altoHero = ((anchoUtil - 14) / 2 / 1.5).clamp(400.0, 430.0);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, entrada, child) => Opacity(
        opacity: entrada,
        child: Transform.translate(
          offset: Offset(0, (1 - entrada) * 20),
          child: child,
        ),
      ),
      child: compacto
          ? Column(
              children: [
                caja,
                const SizedBox(height: 10),
                pie,
                const SizedBox(height: 14),
                Center(
                  child: _Mascota(ancho: 300, flota: _flota, chispas: _chispas),
                ),
              ],
            )
          : ConstrainedBox(
              constraints: BoxConstraints(maxHeight: altoHero),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // El recuadro negro ocupa toda la altura: no queda
                  // ningún espacio en blanco debajo.
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: caja),
                        const SizedBox(height: 8),
                        pie,
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.contain,
                      alignment: Alignment.topCenter,
                      child: _Mascota(
                        ancho: altoHero * 1.5,
                        flota: _flota,
                        chispas: _chispas,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Pastilla pequeña del encabezado.
class _Etiqueta extends StatelessWidget {
  const _Etiqueta({
    required this.icono,
    required this.texto,
    required this.tono,
  });

  final IconData icono;
  final String texto;
  final Color tono;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 13, color: tono),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.55,
          ),
          child: Text(
            texto.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: Colors.white,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Cifra del encabezado: número grande con su etiqueta.
class _Dato extends StatelessWidget {
  const _Dato({
    required this.valor,
    required this.etiqueta,
    required this.icono,
  });

  final String valor;
  final String etiqueta;
  final IconData icono;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 14, color: const Color(0xFF7DD3FC)),
        const SizedBox(width: 6),
        Text(
          valor,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          etiqueta,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.72),
          ),
        ),
      ],
    ),
  );
}

/// Fondo animado tipo aurora sobre el recuadro negro: tonos rosaceos y
/// morados que cambian de dirección en bucle, con dos brumas que se
/// desplazan.
class _Aurora extends StatelessWidget {
  const _Aurora({required this.control});

  final Animation<double> control;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: control,
    builder: (context, child) {
      final t = control.value * 2 * math.pi;
      final a = (math.sin(t) + 1) / 2;
      final b = (math.cos(t) + 1) / 2;
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-1 + 0.6 * math.sin(t), -1),
            end: Alignment(1, -0.2 + 0.8 * b),
            colors: [
              Color.lerp(
                const Color(0xFFF472B6),
                const Color(0xFFFB7185),
                a,
              )!.withValues(alpha: 0.60),
              Color.lerp(
                const Color(0xFFA855F7),
                const Color(0xFFDB2777),
                b,
              )!.withValues(alpha: 0.48),
              Color.lerp(
                const Color(0xFF7C3AED),
                const Color(0xFFEC4899),
                a,
              )!.withValues(alpha: 0.55),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: -60 + 90 * a,
              top: -70 + 60 * b,
              child: _Bruma(tamano: 220, color: const Color(0xFFFFD9EC)),
            ),
            Positioned(
              right: -70 + 80 * b,
              bottom: -80 + 70 * a,
              child: _Bruma(tamano: 240, color: const Color(0xFFE9D5FF)),
            ),
          ],
        ),
      );
    },
  );
}

/// Mancha suave que se desplaza dentro del recuadro (efecto aurora).
class _Bruma extends StatelessWidget {
  const _Bruma({required this.tamano, required this.color});

  final double tamano;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: tamano,
    height: tamano,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [color.withValues(alpha: 0.45), color.withValues(alpha: 0)],
      ),
    ),
  );
}

/// Mascota de la promoción flotando sobre su resplandor, con chispas.
///
/// El widget mantiene la relación 1.5 de la imagen (1536×1024) para que
/// no sobre ni un píxel de espacio vacío al escalado.
class _Mascota extends StatelessWidget {
  const _Mascota({
    required this.ancho,
    required this.flota,
    required this.chispas,
  });

  final double ancho;
  final Animation<double> flota;
  final Animation<double> chispas;

  @override
  Widget build(BuildContext context) {
    final alto = ancho / 1.5;
    return SizedBox(
      width: ancho,
      height: alto,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: ancho * 0.62,
            height: ancho * 0.62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFF9A8D4).withValues(alpha: 0.55),
                  const Color(0xFFF9A8D4).withValues(alpha: 0),
                ],
              ),
            ),
          ),
          Positioned(
            top: alto * 0.04,
            left: ancho * 0.16,
            child: _Chispa(control: chispas, tamano: ancho * 0.05),
          ),
          Positioned(
            top: alto * 0.16,
            right: ancho * 0.08,
            child: _Chispa(control: chispas, tamano: ancho * 0.04),
          ),
          AnimatedBuilder(
            animation: flota,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, -9 * math.sin(flota.value * math.pi)),
              child: child,
            ),
            child: Image.asset(
              'assets/images/mascota_graduada.png',
              width: ancho,
              height: alto,
              fit: BoxFit.contain,
              // En las pruebas de widget el PNG puede no llegar a decodificar;
              // el hueco se reserva igual para no mover el resto del diseño.
              errorBuilder: (context, error, stackTrace) =>
                  SizedBox(width: ancho, height: alto),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chispa extends StatelessWidget {
  const _Chispa({required this.control, required this.tamano});

  final Animation<double> control;
  final double tamano;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: control,
    builder: (context, child) =>
        Opacity(opacity: 0.25 + 0.75 * control.value, child: child),
    child: Icon(
      Icons.auto_awesome_rounded,
      size: tamano,
      color: const Color(0xFFFDE68A),
    ),
  );
}

// ---------------------------------------------------------------------------
// Leyenda / filtro de áreas
// ---------------------------------------------------------------------------

class _LeyendaAreas extends StatelessWidget {
  const _LeyendaAreas({
    required this.malla,
    required this.areaActiva,
    required this.onCambiar,
  });

  final MallaCurricular malla;
  final String? areaActiva;
  final ValueChanged<String?> onCambiar;

  @override
  Widget build(BuildContext context) {
    final conteos = <String, int>{};
    for (final curso in malla.cursos) {
      final id = MallaAreas.deCodigo(curso.codigo).id;
      conteos[id] = (conteos[id] ?? 0) + 1;
    }

    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        children: [
          _ChipArea(
            etiqueta: 'Todas',
            icono: Icons.grid_view_rounded,
            color: AppColors.navy,
            tinte: AppColors.surfaceLow,
            texto: AppColors.navy,
            activo: areaActiva == null,
            cantidad: malla.cursos.length,
            onTap: () => onCambiar(null),
          ),
          for (final area in MallaAreas.todas)
            if ((conteos[area.id] ?? 0) > 0)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _ChipArea(
                  etiqueta: area.nombre,
                  icono: area.icono,
                  color: area.color,
                  tinte: area.tinte,
                  texto: area.texto,
                  activo: areaActiva == area.id,
                  cantidad: conteos[area.id]!,
                  onTap: () => onCambiar(area.id),
                ),
              ),
        ],
      ),
    );
  }
}

class _ChipArea extends StatelessWidget {
  const _ChipArea({
    required this.etiqueta,
    required this.icono,
    required this.color,
    required this.tinte,
    required this.texto,
    required this.activo,
    required this.cantidad,
    required this.onTap,
  });

  final String etiqueta;
  final IconData icono;
  final Color color;
  final Color tinte;
  final Color texto;
  final bool activo;
  final int cantidad;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: activo ? color : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: activo ? color : AppColors.border),
        boxShadow: [
          if (activo)
            BoxShadow(
              color: color.withValues(alpha: 0.32),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: activo ? Colors.white : color),
          const SizedBox(width: 6),
          Text(
            etiqueta,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: activo ? Colors.white : AppColors.navy,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: activo ? Colors.white.withValues(alpha: 0.24) : tinte,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              '$cantidad',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: activo ? Colors.white : texto,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Consejo
// ---------------------------------------------------------------------------

class _ConsejoRuta extends StatelessWidget {
  const _ConsejoRuta();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
    decoration: BoxDecoration(
      color: AppColors.infoBg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.cyan.withValues(alpha: 0.28)),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lightbulb_rounded, size: 20, color: AppColors.gold),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Consejo: al tocar un curso se iluminan los que debes tener '
            'aprobados (lo que sigue hacia atrás) y los que desbloquea. '
            'Usa «Tu nivel» para saltar a tu semestre y «Ajustar» para ver '
            'la malla completa.',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.5,
              height: 1.5,
              color: AppColors.navy,
            ),
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Ficha de un curso
// ---------------------------------------------------------------------------

class _FichaCurso extends StatelessWidget {
  const _FichaCurso({
    required this.curso,
    required this.porCodigo,
    required this.dependientes,
    required this.control,
  });

  final CursoCurricular curso;
  final Map<String, CursoCurricular> porCodigo;
  final List<CursoCurricular> dependientes;
  final TableroMalla control;

  @override
  Widget build(BuildContext context) {
    final area = MallaAreas.deCodigo(curso.codigo);
    final previos = [
      for (final codigo in curso.prerequisitos) porCodigo[codigo],
    ].whereType<CursoCurricular>().toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.82,
      ),
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: area.tinte,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(area.icono, size: 13, color: area.color),
                        const SizedBox(width: 6),
                        Text(
                          area.nombre,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: area.texto,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLow,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${curso.creditos} créditos',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                curso.nombre,
                style: const TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${area.nombre} · Nivel ${MallaAreas.romano(curso.nivel)} · '
                '${curso.codigo}',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 20),
              _SeccionRuta(
                titulo: 'Necesitas aprobar antes',
                icono: Icons.lock_rounded,
                color: AppColors.warning,
                cursos: previos,
                vacio:
                    'Sin prerrequisitos: puedes tomarlo desde el primer día.',
              ),
              const SizedBox(height: 16),
              _SeccionRuta(
                titulo: 'Esto desbloquea',
                icono: Icons.rocket_launch_rounded,
                color: AppColors.success,
                cursos: dependientes,
                vacio: 'Curso terminal: no habilita otros de la malla.',
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        control.irA(curso.codigo);
                        Navigator.pop(context, curso.codigo);
                      },
                      icon: const Icon(
                        Icons.center_focus_strong_rounded,
                        size: 18,
                      ),
                      label: const Text('Centrar en el tablero'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lista de cursos de la ruta con salto a cada uno.
class _SeccionRuta extends StatelessWidget {
  const _SeccionRuta({
    required this.titulo,
    required this.icono,
    required this.color,
    required this.cursos,
    required this.vacio,
  });

  final String titulo;
  final IconData icono;
  final Color color;
  final List<CursoCurricular> cursos;
  final String vacio;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icono, size: 15, color: color),
          const SizedBox(width: 7),
          Text(
            titulo.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 1, color: AppColors.border)),
        ],
      ),
      const SizedBox(height: 10),
      if (cursos.isEmpty)
        Text(
          vacio,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12.5,
            height: 1.45,
            color: AppColors.textMuted,
          ),
        )
      else
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final otro in cursos)
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => Navigator.pop(context, otro.codigo),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLow,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: MallaAreas.deCodigo(otro.codigo).color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        otro.codigo,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 150),
                        child: Text(
                          otro.nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
    ],
  );
}
