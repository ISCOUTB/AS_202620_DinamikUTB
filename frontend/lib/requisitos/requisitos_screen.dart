import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/widgets/async_view.dart';
import 'package:frontend/core/widgets/page_list.dart';
import 'package:frontend/core/widgets/responsive_grid.dart';
import 'package:frontend/estudiantes/progreso_models.dart';
import 'package:frontend/estudiantes/progreso_service.dart';
import 'package:frontend/estudiantes/widgets/requisito_ruta_card.dart';
import 'models.dart';
import 'requisito_card.dart';
import 'requisitos_service.dart';

/// Consulta los requisitos del estudiante.
///
/// Cuando la pantalla se abre desde el shell autenticado se muestra la ruta
/// completa de grado con las mismas tarjetas del inicio, sobre un degradado
/// cálido y con un encabezado al estilo de la malla.
class RequisitosScreen extends StatefulWidget {
  const RequisitosScreen({
    super.key,
    required this.service,
    required this.estudianteId,
  });

  final RequisitosService service;
  final String estudianteId;

  @override
  State<RequisitosScreen> createState() => _RequisitosScreenState();
}

class _RequisitosScreenState extends State<RequisitosScreen> {
  EstadoRequisito? _filtro;

  @override
  Widget build(BuildContext context) {
    // En las pruebas de widget la pantalla se monta sin ApiClient; en ese caso
    // se conserva la vista sencilla de requisitos.
    ApiClient? api;
    try {
      api = context.read<ApiClient>();
    } on ProviderNotFoundException {
      api = null;
    }

    if (api != null) {
      return _FondoRequisitos(
        child: AsyncView<List<RutaRequisito>>(
          load: () => ProgresoService(api!).obtenerRuta(widget.estudianteId),
          builder: (context, ruta) => _ContenidoRuta(ruta: ruta),
        ),
      );
    }

    return AsyncView<List<Requisito>>(
      load: () => widget.service.obtenerRequisitos(widget.estudianteId),
      builder: (context, requisitos) {
        if (requisitos.isEmpty) {
          return const PageList(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(child: Text('No tienes requisitos registrados.')),
              ),
            ],
          );
        }
        final visibles = _filtro == null
            ? requisitos
            : requisitos.where((r) => r.estado == _filtro).toList();
        return PageList(
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Todos'),
                  selected: _filtro == null,
                  onSelected: (_) => setState(() => _filtro = null),
                ),
                for (final estado in EstadoRequisito.values)
                  ChoiceChip(
                    label: Text(switch (estado) {
                      EstadoRequisito.cumplido => 'Cumplidos',
                      EstadoRequisito.enProceso => 'En curso',
                      EstadoRequisito.pendiente => 'Pendientes',
                    }),
                    selected: _filtro == estado,
                    onSelected: (_) => setState(() => _filtro = estado),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (visibles.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 32),
                child: Center(
                  child: Text(
                    'No hay requisitos con este estado.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              )
            else
              ResponsiveGrid(
                minTileWidth: 320,
                children: [
                  for (final r in visibles) RequisitoCard(requisito: r),
                ],
              ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Fondo cálido de la pantalla
// ---------------------------------------------------------------------------

class _FondoRequisitos extends StatelessWidget {
  const _FondoRequisitos({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const DecoratedBox(
        decoration: BoxDecoration(color: Color(0xFFE00D3B)),
      ),
      Image.asset(
        'assets/images/requisitos_fondo.png',
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder: (context, error, stack) => const SizedBox.shrink(),
      ),
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x14000000), Color(0x52000000)],
          ),
        ),
      ),
      SafeArea(child: child),
    ],
  );
}

// ---------------------------------------------------------------------------
// Contenido: encabezado estilo malla + tarjetas del inicio
// ---------------------------------------------------------------------------

class _ContenidoRuta extends StatelessWidget {
  const _ContenidoRuta({required this.ruta});

  final List<RutaRequisito> ruta;

  @override
  Widget build(BuildContext context) {
    final compacto = MediaQuery.sizeOf(context).width < 640;
    final cumplidos = ruta.where((r) => r.estado == 'cumplido').length;
    final enCurso = ruta.where((r) => r.estado == 'en_proceso').length;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(compacto ? 14 : 28, 16, compacto ? 14 : 28, 40),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: _HeroRequisitos(
              total: ruta.length,
              cumplidos: cumplidos,
              enCurso: enCurso,
            ),
          ),
        ),
        const SizedBox(height: 26),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu ruta hacia el grado',
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: compacto ? 22 : 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Despliega cada requisito para ver cómo cumplirlo, '
                  'a qué oficina ir y cuánto demora.',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: compacto ? 12.5 : 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 16),
                if (ruta.isEmpty)
                  Text(
                    'Aún no tienes requisitos de grado asignados.',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  )
                else
                  ResponsiveGrid(
                    minTileWidth: 340,
                    spacing: 14,
                    children: [
                      for (var i = 0; i < ruta.length; i++)
                        RequisitoRutaCard(requisito: ruta[i]),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroRequisitos extends StatefulWidget {
  const _HeroRequisitos({
    required this.total,
    required this.cumplidos,
    required this.enCurso,
  });

  final int total;
  final int cumplidos;
  final int enCurso;

  @override
  State<_HeroRequisitos> createState() => _HeroRequisitosState();
}

class _HeroRequisitosState extends State<_HeroRequisitos>
    with TickerProviderStateMixin {
  late final AnimationController _aurora = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 7000),
  )..repeat();

  late final AnimationController _flota = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    if (MediaQuery.disableAnimationsOf(context)) {
      _aurora
        ..stop()
        ..value = 0.5;
      _flota
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _aurora.dispose();
    _flota.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compacto = MediaQuery.sizeOf(context).width < 640;

    final caja = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
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
              compacto ? 18 : 26,
              compacto ? 20 : 24,
              compacto ? 18 : 26,
              compacto ? 18 : 22,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Etiqueta(
                          icono: Icons.checklist_rounded,
                          texto: 'Requisitos de grado',
                          tono: const Color(0xFF7DD3FC),
                        ),
                        _Etiqueta(
                          icono: Icons.emoji_events_rounded,
                          texto: 'Ruta UTB',
                          tono: AppColors.gold,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Requisitos de grado',
                        style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: compacto ? 34 : 46,
                          fontWeight: FontWeight.w800,
                          height: 1.03,
                          letterSpacing: -0.8,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Todo lo que necesitas cerrar para llegar a tu grado, '
                      'con su guía y su estado actual.',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: compacto ? 12.5 : 14,
                        height: 1.4,
                        color: Colors.white.withValues(alpha: 0.86),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Dato(
                      valor: '${widget.total}',
                      etiqueta: 'requisitos',
                      icono: Icons.list_alt_rounded,
                    ),
                    _Dato(
                      valor: '${widget.cumplidos}',
                      etiqueta: 'cumplidos',
                      icono: Icons.verified_rounded,
                    ),
                    _Dato(
                      valor: '${widget.enCurso}',
                      etiqueta: 'en curso',
                      icono: Icons.autorenew_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final anchoUtil = math.min(MediaQuery.sizeOf(context).width - 48, 1180);
    final altoHero = ((anchoUtil - 14) / 2 / 1.5).clamp(280.0, 350.0);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 620),
      curve: Curves.easeOutCubic,
      builder: (context, entrada, child) => Opacity(
        opacity: entrada,
        child: Transform.translate(
          offset: Offset(0, (1 - entrada) * 18),
          child: child,
        ),
      ),
      child: compacto
          ? Column(
              children: [
                SizedBox(height: altoHero * 0.82, child: caja),
                const SizedBox(height: 10),
                Center(
                  child: _Mascota(ancho: 230, flota: _flota),
                ),
              ],
            )
          : ConstrainedBox(
              constraints: BoxConstraints(maxHeight: altoHero),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      child: _Mascota(
                        ancho: altoHero,
                        flota: _flota,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: caja),
                ],
              ),
            ),
    );
  }
}

class _Aurora extends StatelessWidget {
  const _Aurora({required this.control});

  final Animation<double> control;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: control,
    builder: (context, _) {
      final t = (math.sin(control.value * 2 * math.pi) + 1) / 2;
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(
                const Color(0xFF9CA3AF),
                const Color(0xFF4B5563),
                t,
              )!.withValues(alpha: 0.55),
              Color.lerp(
                const Color(0xFF4B5563),
                const Color(0xFF1F2937),
                t,
              )!.withValues(alpha: 0.5),
              const Color(0xFF050505).withValues(alpha: 0.95),
            ],
          ),
        ),
      );
    },
  );
}

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
      color: tono.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: tono.withValues(alpha: 0.45)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 15, color: tono),
        const SizedBox(width: 6),
        Text(
          texto,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: tono,
          ),
        ),
      ],
    ),
  );
}

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
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 17, color: const Color(0xFFE2E8F0)),
        const SizedBox(width: 7),
        Text(
          valor,
          style: const TextStyle(
            fontFamily: 'Syne',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          etiqueta,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 11.5,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    ),
  );
}

class _Mascota extends StatelessWidget {
  const _Mascota({required this.ancho, required this.flota});

  final double ancho;
  final Animation<double> flota;

  @override
  Widget build(BuildContext context) {
    final alto = ancho;
    return SizedBox(
      width: ancho,
      height: alto,
      child: AnimatedBuilder(
        animation: flota,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, -9 * math.sin(flota.value * math.pi)),
          child: child,
        ),
        child: Image.asset(
          'assets/images/mascota_requisitos.png',
          width: ancho,
          height: alto,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stack) =>
              SizedBox(width: ancho, height: alto),
        ),
      ),
    );
  }
}
