import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/badges.dart';
import '../../core/theme/colors.dart';
import '../models/badge_model.dart';

class BadgeCelebrationOverlay extends StatefulWidget {
  const BadgeCelebrationOverlay({
    super.key,
    required this.badges,
    required this.child,
  });

  final List<BadgeModel> badges;
  final Widget child;

  @override
  State<BadgeCelebrationOverlay> createState() =>
      _BadgeCelebrationOverlayState();
}

class _BadgeCelebrationOverlayState extends State<BadgeCelebrationOverlay>
    with TickerProviderStateMixin {
  int _index = 0;
  bool _finished = false;
  Timer? _timer;
  late final AnimationController _scale;
  late final AnimationController _fx;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scale = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fx = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _scaleAnim = CurvedAnimation(
      parent: _scale,
      curve: Curves.elasticOut,
    );
    if (widget.badges.isNotEmpty) {
      _scale.forward();
      _armTimer();
    } else {
      _finished = true;
    }
  }

  @override
  void didUpdateWidget(covariant BadgeCelebrationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.badges != widget.badges) {
      _timer?.cancel();
      _index = 0;
      _finished = widget.badges.isEmpty;
      if (widget.badges.isNotEmpty) {
        _scale.forward(from: 0);
        _armTimer();
      }
    }
  }

  void _armTimer() {
    _timer?.cancel();
    if (_finished || widget.badges.isEmpty) {
      return;
    }
    _timer = Timer(const Duration(seconds: 3), _advance);
  }

  void _advance() {
    _timer?.cancel();
    if (!mounted) {
      return;
    }
    if (_index + 1 < widget.badges.length) {
      setState(() => _index++);
      _scale.forward(from: 0);
      _armTimer();
    } else {
      setState(() => _finished = true);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scale.dispose();
    _fx.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.badges.isEmpty || _finished) {
      return widget.child;
    }
    final badge = widget.badges[_index];
    final def = kBadgeById[badge.id];

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _advance,
            child: AnimatedBuilder(
              animation: _fx,
              builder: (context, _) {
                return CustomPaint(
                  painter: _ParticlePainter(
                    t: _fx.value,
                    seed: _index * 9973,
                  ),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.55),
                    alignment: Alignment.center,
                    child: ScaleTransition(
                      scale: _scaleAnim,
                      child: ShaderMask(
                        blendMode: BlendMode.srcATop,
                        shaderCallback: (bounds) {
                          final shift =
                              math.sin(_fx.value * math.pi * 2) * 0.15;
                          return LinearGradient(
                            colors: [
                              AppColors.gold.withValues(alpha: 0.2),
                              Colors.white,
                              AppColors.primary.withValues(alpha: 0.35),
                              Colors.white,
                              AppColors.gold.withValues(alpha: 0.2),
                            ],
                            stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                            begin: Alignment(-1 + shift, -0.5),
                            end: Alignment(1 - shift, 0.5),
                          ).createShader(bounds);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                def?.icon ?? '🏅',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 88,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                def?.name ?? 'Badge',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 26,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                def?.description ?? '',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  fontSize: 16,
                                  height: 1.35,
                                ),
                              ),
                              if (widget.badges.length > 1) ...[
                                const SizedBox(height: 20),
                                Text(
                                  '${_index + 1} / ${widget.badges.length}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.65),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({required this.t, required this.seed});

  final double t;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed);
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 48; i++) {
      final ox = rnd.nextDouble();
      final oy = rnd.nextDouble();
      final phase = rnd.nextDouble() * math.pi * 2;
      final speed = 0.4 + rnd.nextDouble() * 0.9;
      final x =
          (ox + math.sin(phase + t * math.pi * 2 * speed) * 0.08) * size.width;
      final y = (oy + t * speed * 0.35 + math.cos(phase + t * math.pi) * 0.05) *
          size.height;
      if (y > size.height * 1.1) {
        continue;
      }
      final a = (0.15 + rnd.nextDouble() * 0.45) * (1 - t * 0.15);
      paint.color = (i.isEven ? AppColors.primary : AppColors.gold)
          .withValues(alpha: a.clamp(0.0, 1.0));
      final r = 1.2 + rnd.nextDouble() * 2.8;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.seed != seed;
}
