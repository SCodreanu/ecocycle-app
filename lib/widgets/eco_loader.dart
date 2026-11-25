import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A short brand reveal at launch, or a repeating compact loading indicator.
class EcoLoader extends StatefulWidget {
  const EcoLoader({super.key, this.onComplete, this.launch = false});

  final VoidCallback? onComplete;
  final bool launch;

  @override
  State<EcoLoader> createState() => _EcoLoaderState();
}

class _EcoLoaderState extends State<EcoLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.launch ? 2200 : 1800),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.launch) {
        _controller.forward().whenCompleteOrCancel(() {
          if (mounted && _controller.isCompleted) widget.onComplete?.call();
        });
      } else {
        _controller.repeat();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final size = widget.launch ? 180.0 : 88.0;
    return Semantics(
      label: 'Caricamento EcoCycle',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = reduced ? 1.0 : _controller.value;
          final reveal = ((t - 0.40) / 0.35).clamp(0.0, 1.0).toDouble();
          final fade = widget.launch || reduced
              ? 1.0
              : ((1.0 - t) / 0.10).clamp(0.0, 1.0).toDouble();
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: size,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (reveal < 1)
                      Opacity(
                        opacity: 1 - reveal,
                        child: CustomPaint(
                          painter: _ArrowPainter(t * 2 * math.pi),
                        ),
                      ),
                    if (reveal > 0)
                      Opacity(
                        opacity: fade,
                        child: ClipPath(
                          clipper: _RevealClipper(reveal),
                          child: Image.asset('assets/branding/splash_logo.png'),
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.launch)
                Opacity(
                  opacity: reveal,
                  child: const Text(
                    'EcoCycle',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter(this.angle);
  final double angle;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * 0.26;
    const sweep = math.pi * 1.4;
    final paint = Paint()
      ..color = const Color(0xFF79D768)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.065
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      angle,
      sweep,
      false,
      paint,
    );
    final end = angle + sweep;
    final tip = center + Offset(math.cos(end), math.sin(end)) * radius;
    final tangent = Offset(-math.sin(end), math.cos(end));
    final normal = Offset(math.cos(end), math.sin(end));
    final head = size.width * 0.09;
    final path = Path()
      ..moveTo(tip.dx + tangent.dx * head, tip.dy + tangent.dy * head)
      ..lineTo(
        tip.dx - tangent.dx * head + normal.dx * head,
        tip.dy - tangent.dy * head + normal.dy * head,
      )
      ..lineTo(
        tip.dx - tangent.dx * head - normal.dx * head,
        tip.dy - tangent.dy * head - normal.dy * head,
      )
      ..close();
    canvas.drawPath(path, Paint()..color = paint.color);
  }

  @override
  bool shouldRepaint(_ArrowPainter oldDelegate) => oldDelegate.angle != angle;
}

class _RevealClipper extends CustomClipper<Path> {
  const _RevealClipper(this.progress);
  final double progress;

  @override
  Path getClip(Size size) {
    if (progress >= 1) return Path()..addRect(Offset.zero & size);
    final center = size.center(Offset.zero);
    final circle = Rect.fromCircle(center: center, radius: size.longestSide);
    return Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(circle, math.pi / 2, progress * 2 * math.pi, false)
      ..close();
  }

  @override
  bool shouldReclip(_RevealClipper oldClipper) =>
      oldClipper.progress != progress;
}
