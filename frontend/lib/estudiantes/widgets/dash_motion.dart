import 'package:flutter/material.dart';

/// Aparece (fundido + deslizamiento corto) cuando entra a la pantalla al hacer
/// scroll. Con animaciones reducidas aparece de una vez.
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 24,
  });

  final Widget child;
  final Duration delay;
  final double offset;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  ScrollPosition? _pos;
  bool _visto = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _visto = true;
      _c.value = 1;
      return;
    }
    final nueva = Scrollable.maybeOf(context)?.position;
    if (!identical(nueva, _pos)) {
      _pos?.removeListener(_revisar);
      _pos = nueva;
      _pos?.addListener(_revisar);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _revisar());
  }

  void _revisar() {
    if (_visto || !mounted) return;
    final caja = context.findRenderObject();
    if (caja is! RenderBox || !caja.attached) return;
    final arriba = caja.localToGlobal(Offset.zero).dy;
    if (arriba < MediaQuery.sizeOf(context).height * 0.94) {
      _visto = true;
      Future<void>.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _pos?.removeListener(_revisar);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    child: widget.child,
    builder: (context, child) {
      final v = Curves.easeOutCubic.transform(_c.value);
      return Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, (1 - v) * widget.offset),
          child: child,
        ),
      );
    },
  );
}

/// Número que cuenta desde cero hasta [value].
class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    required this.style,
    this.decimals = 0,
    this.suffix = '',
  });

  final double value;
  final TextStyle style;
  final int decimals;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final reducir = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: reducir ? Duration.zero : const Duration(milliseconds: 1600),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) =>
          Text('${v.toStringAsFixed(decimals).replaceAll('.', ',')}$suffix', style: style),
    );
  }
}
