import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';

class AuthGradientBackground extends StatefulWidget {
  const AuthGradientBackground({super.key, required this.child});

  final Widget child;

  @override
  State<AuthGradientBackground> createState() => _AuthGradientBackgroundState();
}

class _AuthGradientBackgroundState extends State<AuthGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _DriftGradientPainter(progress: _controller.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _DriftGradientPainter extends CustomPainter {
  _DriftGradientPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = AppColors.background);

    final t = progress * 2 * math.pi;
    final w = size.width;
    final h = size.height;
    final s = math.min(w, h);

    void drawGlow(Offset c, Color color, double radius, double alpha) {
      final g = RadialGradient(
        colors: [
          color.withValues(alpha: alpha),
          color.withValues(alpha: 0),
        ],
        stops: const [0.0, 1.0],
      );
      final r = Rect.fromCircle(center: c, radius: radius * s);
      canvas.drawRect(
        rect,
        Paint()
          ..blendMode = BlendMode.screen
          ..shader = g.createShader(r),
      );
    }

    drawGlow(
      Offset(w * (0.28 + 0.1 * math.sin(t)),
          h * (0.22 + 0.08 * math.cos(t * 1.07))),
      AppColors.primary,
      0.55,
      0.35,
    );
    drawGlow(
      Offset(w * (0.78 + 0.07 * math.cos(t * 0.93)),
          h * (0.62 + 0.09 * math.sin(t * 1.12))),
      AppColors.ghostBlue,
      0.45,
      0.22,
    );
    drawGlow(
      Offset(w * (0.52 + 0.06 * math.sin(t * 1.4)),
          h * (0.48 + 0.05 * math.cos(t * 0.8))),
      AppColors.card,
      0.5,
      0.12,
    );

    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.45),
        ],
        stops: const [0.45, 1.0],
        radius: 1.05,
      ).createShader(
          Rect.fromCircle(center: Offset(w / 2, h / 2), radius: s * 0.95));
    canvas.drawRect(rect, vignette);
  }

  @override
  bool shouldRepaint(covariant _DriftGradientPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
