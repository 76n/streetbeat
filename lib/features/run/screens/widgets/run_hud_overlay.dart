import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/location_utils.dart';
import '../../models/active_objective.dart';
import '../../models/run_model.dart';

class RunHudOverlay extends StatelessWidget {
  const RunHudOverlay({
    super.key,
    required this.run,
    required this.distanceLabel,
    required this.paceLabel,
    required this.timerLabel,
    required this.score,
    required this.scoreKey,
    required this.multiplier,
    required this.streetbeatActive,
    required this.streetbeatEndsAt,
    required this.multiplierPulse,
    required this.ringProgress,
    required this.objective,
    required this.objectiveKey,
    required this.onPause,
    required this.onStop,
    required this.ghostVisible,
    required this.onGhostToggle,
    required this.scoreScale,
  });

  final RunModel run;
  final String distanceLabel;
  final String paceLabel;
  final String timerLabel;
  final int score;
  final GlobalKey scoreKey;
  final double multiplier;
  final bool streetbeatActive;
  final DateTime? streetbeatEndsAt;
  final double multiplierPulse;
  final double ringProgress;
  final ActiveObjective objective;
  final Key objectiveKey;
  final VoidCallback onPause;
  final VoidCallback onStop;
  final bool ghostVisible;
  final ValueChanged<bool> onGhostToggle;
  final double scoreScale;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 12,
            right: 12,
            child: _TopBarCard(
              distanceLabel: distanceLabel,
              paceLabel: paceLabel,
              timerLabel: timerLabel,
              score: score,
              scoreKey: scoreKey,
              scoreScale: scoreScale,
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 88,
            left: 16,
            right: 16,
            child: _MultiplierStrip(
              multiplier: multiplier,
              pulse: multiplierPulse,
              streetbeatActive: streetbeatActive,
              streetbeatEndsAt: streetbeatEndsAt,
              ringProgress: ringProgress,
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.paddingOf(context).bottom + 112,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 380),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, anim) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.08, 0),
                    end: Offset.zero,
                  ).animate(anim),
                  child: FadeTransition(opacity: anim, child: child),
                );
              },
              child: _ObjectiveCard(
                key: objectiveKey,
                label: '${objective.label} →',
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.paddingOf(context).bottom + 20,
            child: _BottomControls(
              onPause: onPause,
              onStop: onStop,
              ghostVisible: ghostVisible,
              onGhostToggle: onGhostToggle,
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> showPauseSheet(
    BuildContext context, {
    required RunModel run,
    required String paceLabel,
    required String timerLabel,
    required VoidCallback onResume,
    required VoidCallback onEndRun,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              color: AppColors.surface.withValues(alpha: 0.92),
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                24 + MediaQuery.paddingOf(ctx).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Paused',
                    textAlign: TextAlign.center,
                    style: Theme.of(ctx).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 20),
                  _StatRow(
                      'Distance', LocationUtils.formatDistance(run.distance)),
                  _StatRow('Score', '${run.totalScore}'),
                  _StatRow('Pace', paceLabel),
                  _StatRow('Time', timerLabel),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      onResume();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Resume'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      onEndRun();
                    },
                    child: Text(
                      'End run',
                      style: TextStyle(
                        color: Colors.red.shade300,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBarCard extends StatelessWidget {
  const _TopBarCard({
    required this.distanceLabel,
    required this.paceLabel,
    required this.timerLabel,
    required this.score,
    required this.scoreKey,
    required this.scoreScale,
  });

  final String distanceLabel;
  final String paceLabel;
  final String timerLabel;
  final int score;
  final GlobalKey scoreKey;
  final double scoreScale;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    distanceLabel,
                    style: AppTextStyles.hudPrimary(28),
                  ),
                ),
                Expanded(
                  child: Text(
                    paceLabel,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.hudSecondary(14).copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  timerLabel,
                  style: AppTextStyles.hudPrimary(20),
                ),
                const SizedBox(width: 10),
                Transform.scale(
                  scale: scoreScale,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '$score',
                    key: scoreKey,
                    style: AppTextStyles.hudPrimary(22).copyWith(
                      color: AppColors.gold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MultiplierStrip extends StatelessWidget {
  const _MultiplierStrip({
    required this.multiplier,
    required this.pulse,
    required this.streetbeatActive,
    required this.streetbeatEndsAt,
    required this.ringProgress,
  });

  final double multiplier;
  final double pulse;
  final bool streetbeatActive;
  final DateTime? streetbeatEndsAt;
  final double ringProgress;

  String _label() {
    if (streetbeatActive || (multiplier - 10).abs() < 0.01) {
      return 'STREETBEAT';
    }
    if ((multiplier % 1).abs() < 0.01 || (multiplier % 1 - 0.5).abs() < 0.01) {
      return '${multiplier.toStringAsFixed(multiplier == 1.5 ? 1 : 0)}x';
    }
    return '${multiplier.toStringAsFixed(1)}x';
  }

  List<Color> _gradient() {
    if (streetbeatActive) {
      return [
        const Color(0xFFFFE082),
        const Color(0xFFFFD700),
        const Color(0xFFFF6F00),
      ];
    }
    if (multiplier >= 5) {
      return [
        Colors.white,
        AppColors.gold,
        const Color(0xFFFF6F00),
      ];
    }
    if (multiplier >= 3) {
      return [
        Colors.white,
        AppColors.gold,
        Colors.deepOrange,
      ];
    }
    if (multiplier >= 2) {
      return [
        Colors.white,
        const Color(0xFFFFD54F),
        AppColors.primary,
      ];
    }
    return [
      Colors.white70,
      Colors.white,
      const Color(0xFFFFE082),
    ];
  }

  double _fillT() {
    const steps = [1.0, 1.5, 2.0, 3.0, 5.0, 10.0];
    var i = 0;
    for (; i < steps.length; i++) {
      if (multiplier <= steps[i] + 0.01) {
        break;
      }
    }
    if (i >= steps.length) {
      return 1;
    }
    final low = i == 0 ? 1.0 : steps[i - 1];
    final high = steps[i];
    final t = ((multiplier - low) / (high - low)).clamp(0.0, 1.0);
    return (i + t) / steps.length;
  }

  @override
  Widget build(BuildContext context) {
    final scale = 1.0 + 0.04 * pulse;
    final fill = _fillT();
    return Transform.scale(
      scale: scale,
      alignment: Alignment.center,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.black.withValues(alpha: 0.35),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: fill,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(colors: _gradient()),
                    boxShadow: streetbeatActive
                        ? [
                            BoxShadow(
                              color: AppColors.gold.withValues(alpha: 0.45),
                              blurRadius: 12,
                              spreadRadius: 0,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: -26,
            child: SizedBox(
              width: 52,
              height: 52,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (streetbeatActive && streetbeatEndsAt != null)
                    CustomPaint(
                      size: const Size(52, 52),
                      painter: _RingPainter(progress: ringProgress),
                    ),
                  Text(
                    _label(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: streetbeatActive ? 9 : 11,
                      fontWeight: FontWeight.w900,
                      color: streetbeatActive ? AppColors.gold : Colors.white,
                      height: 1.05,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 2;
    final bg = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(c, r, bg);
    final fg = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _ObjectiveCard extends StatelessWidget {
  const _ObjectiveCard({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  const _BottomControls({
    required this.onPause,
    required this.onStop,
    required this.ghostVisible,
    required this.onGhostToggle,
  });

  final VoidCallback onPause;
  final VoidCallback onStop;
  final bool ghostVisible;
  final ValueChanged<bool> onGhostToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CircleBtn(
          icon: Icons.pause_rounded,
          onTap: onPause,
          color: AppColors.surface.withValues(alpha: 0.85),
        ),
        const SizedBox(width: 20),
        _StopFab(onStop: onStop),
        const SizedBox(width: 20),
        _CircleBtn(
          icon: ghostVisible
              ? Icons.visibility_rounded
              : Icons.visibility_off_rounded,
          onTap: () {
            HapticFeedback.selectionClick();
            onGhostToggle(!ghostVisible);
          },
          color: ghostVisible
              ? AppColors.ghostBlue.withValues(alpha: 0.35)
              : AppColors.surface.withValues(alpha: 0.85),
        ),
      ],
    );
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(icon, size: 26, color: Colors.white),
        ),
      ),
    );
  }
}

class _StopFab extends StatefulWidget {
  const _StopFab({required this.onStop});

  final VoidCallback onStop;

  @override
  State<_StopFab> createState() => _StopFabState();
}

class _StopFabState extends State<_StopFab>
    with SingleTickerProviderStateMixin {
  static const _holdDuration = Duration(milliseconds: 500);
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: _holdDuration,
  );
  bool _endedRun = false;

  @override
  void initState() {
    super.initState();
    _progress.addStatusListener(_onProgressStatus);
  }

  void _onProgressStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted && !_endedRun) {
      _endedRun = true;
      _progress.reset();
      HapticFeedback.heavyImpact();
      widget.onStop();
    }
  }

  @override
  void dispose() {
    _progress.removeStatusListener(_onProgressStatus);
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) {
        _endedRun = false;
        HapticFeedback.lightImpact();
        _progress.forward(from: 0);
      },
      onPointerUp: (_) {
        if (!_endedRun && !_progress.isCompleted) {
          _progress.reset();
        }
      },
      onPointerCancel: (_) {
        if (!_endedRun && !_progress.isCompleted) {
          _progress.reset();
        }
      },
      child: Material(
        color: const Color(0xFFC62828),
        elevation: 8,
        shadowColor: Colors.red.withValues(alpha: 0.5),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: 76,
          height: 76,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _progress,
                builder: (context, child) {
                  return CircularProgressIndicator(
                    value: _progress.value,
                    strokeWidth: 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    color: Colors.white,
                  );
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'HOLD',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
