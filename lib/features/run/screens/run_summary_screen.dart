import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/badges.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/location_utils.dart';
import '../../../shared/models/badge_model.dart';
import '../../../shared/widgets/badge_celebration.dart';
import '../models/coin_model.dart';
import '../models/run_model.dart';
import '../models/run_summary_payload.dart';
import 'widgets/run_summary_map_replay.dart';

class RunSummaryScreen extends StatefulWidget {
  const RunSummaryScreen({super.key, this.payload});

  final RunSummaryPayload? payload;

  @override
  State<RunSummaryScreen> createState() => _RunSummaryScreenState();
}

class _RunSummaryScreenState extends State<RunSummaryScreen>
    with TickerProviderStateMixin {
  final GlobalKey _shareBoundaryKey = GlobalKey();
  late final AnimationController _flame;
  late final AnimationController _shimmer;
  late final AnimationController _streakBurst;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _flame = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _streakBurst = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    final p = widget.payload;
    if (p != null &&
        p.currentStreakWeeks > p.previousStreakWeeks &&
        p.currentStreakWeeks >= 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _streakBurst.forward();
      });
    }
  }

  @override
  void dispose() {
    _flame.dispose();
    _shimmer.dispose();
    _streakBurst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.payload;
    if (p == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Summary')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No run data.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/home'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      );
    }

    final r = p.run;
    final gatesHit = r.gates.where((g) => g.isCapture).length;
    final gatesMissed = r.gates.where((g) => g.isMissed).length;
    final coinTypes = _coinTypeBreakdown(r.coins);

    return BadgeCelebrationOverlay(
      badges: p.newlyEarnedBadges,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          fit: StackFit.expand,
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: AppColors.background.withValues(alpha: 0.92),
                  surfaceTintColor: Colors.transparent,
                  title: const Text('Run complete'),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: r.route.length >= 2
                        ? RunSummaryMapReplay(
                            route: r.route,
                            ghostRoute: p.ghostRoute,
                            coins: r.coins,
                            gates: r.gates,
                          )
                        : const _RoutePlaceholder(height: 200),
                  ),
                ),
                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverToBoxAdapter(
                    child: _StatsRow(
                      distanceM: r.distance,
                      durationSec: r.durationSeconds,
                      avgPace: r.averagePace,
                      elevationM: r.elevationGain,
                    ),
                  ),
                ),
                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverToBoxAdapter(
                    child: _ScoreBreakdownCard(
                      run: r,
                      coinTypes: coinTypes,
                      gatesHit: gatesHit,
                      gatesMissed: gatesMissed,
                    ),
                  ),
                ),
                if (p.hadGhost)
                  SliverPadding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverToBoxAdapter(
                      child: _GhostSection(
                        payload: p,
                      ),
                    ),
                  ),
                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverToBoxAdapter(
                    child: _StreakCard(
                      payload: p,
                      flameAnimation: _flame,
                    ),
                  ),
                ),
                if (p.newlyEarnedBadges.isNotEmpty)
                  SliverPadding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverToBoxAdapter(
                      child: _BadgesSection(
                        badges: p.newlyEarnedBadges,
                        shimmer: _shimmer,
                      ),
                    ),
                  ),
                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverToBoxAdapter(
                    child: _TomorrowHookCard(text: _tomorrowHook(p)),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    24 + MediaQuery.paddingOf(context).bottom,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _BottomActions(
                      sharing: _sharing,
                      onShare: () => _shareRun(context, p),
                      onDone: () => context.go('/home'),
                    ),
                  ),
                ),
              ],
            ),
            if (p.personalBestBeaten)
              Positioned(
                top: MediaQuery.paddingOf(context).top + 52,
                left: 16,
                right: 16,
                child: Material(
                  color: AppColors.gold.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    child: Text(
                      '🏆 New Personal Best!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF1A1200),
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _streakBurst,
                  builder: (context, child) {
                    if (_streakBurst.value == 0) {
                      return const SizedBox.shrink();
                    }
                    return Opacity(
                      opacity: (1 - _streakBurst.value) * 0.35,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.4),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Transform.scale(
                          scale: 0.8 + _streakBurst.value * 0.5,
                          child: Text(
                            'STREAK +${p.currentStreakWeeks - p.previousStreakWeeks}',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: AppColors.gold.withValues(
                                alpha: 1 - _streakBurst.value * 0.8,
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
            Offstage(
              child: RepaintBoundary(
                key: _shareBoundaryKey,
                child: _ShareCard(payload: p),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareRun(BuildContext context, RunSummaryPayload p) async {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sharing = true);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final boundary = _shareBoundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null || !mounted) {
        return;
      }
      final image = await boundary.toImage(pixelRatio: dpr.clamp(2.0, 3.0));
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null || !mounted) {
        return;
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/streetbeat_run_${p.run.id}.png');
      await file.writeAsBytes(bytes.buffer.asUint8List());
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'StreetBeat · ${LocationUtils.formatDistance(p.run.distance)} · ${p.run.totalScore} pts',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text('Share failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _sharing = false);
      }
    }
  }
}

String _tomorrowHook(RunSummaryPayload p) {
  final r = p.run;
  if (p.personalBestBeaten) {
    return 'New ghost set. Can you beat it?';
  }
  if (p.hadGhost && r.ghostDelta >= 1) {
    return 'Your ghost just got harder to beat. Come back tomorrow.';
  }
  if (p.hadGhost && r.ghostDelta <= -1) {
    return 'Tight race today — shave a few seconds off tomorrow.';
  }
  if (p.runsThisWeekAfterRun < p.weeklyGoalRuns &&
      p.runsThisWeekAfterRun == p.weeklyGoalRuns - 1) {
    return 'One more run this week keeps your streak alive.';
  }
  if (r.maxMultiplier >= 5 && r.streetbeatCount == 0 && r.totalScore > 0) {
    return 'You were close to STREETBEAT. Stack those coins tomorrow.';
  }
  return 'Great work. See you on the road tomorrow.';
}

Map<CoinType, int> _coinTypeBreakdown(List<CoinModel> coins) {
  final m = <CoinType, int>{};
  for (final c in coins.where((e) => e.isCollected)) {
    m[c.type] = (m[c.type] ?? 0) + 1;
  }
  return m;
}

class _RoutePlaceholder extends StatelessWidget {
  const _RoutePlaceholder({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.surface,
      ),
      child: const Icon(
        Icons.route_rounded,
        size: 48,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _StatsRow extends StatefulWidget {
  const _StatsRow({
    required this.distanceM,
    required this.durationSec,
    required this.avgPace,
    required this.elevationM,
  });

  final double distanceM;
  final int durationSec;
  final String? avgPace;
  final double elevationM;

  @override
  State<_StatsRow> createState() => _StatsRowState();
}

class _StatsRowState extends State<_StatsRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(_c.value);
        final d = widget.distanceM * t;
        final sec = (widget.durationSec * t).round();
        final el = widget.elevationM * t;
        return Row(
          children: [
            Expanded(
              child: _statCell(
                'Distance',
                LocationUtils.formatDistance(d),
              ),
            ),
            Expanded(
              child: _statCell(
                'Time',
                _fmtDuration(sec),
              ),
            ),
            Expanded(
              child: _statCell(
                'Avg pace',
                t > 0.88 ? (widget.avgPace ?? '—') : '…',
              ),
            ),
            Expanded(
              child: _statCell(
                'Elev',
                '${el.round()} m',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _statCell(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDuration(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    final h = m ~/ 60;
    final mm = m % 60;
    if (h > 0) {
      return '${h}h ${mm}m';
    }
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }
}

class _ScoreBreakdownCard extends StatefulWidget {
  const _ScoreBreakdownCard({
    required this.run,
    required this.coinTypes,
    required this.gatesHit,
    required this.gatesMissed,
  });

  final RunModel run;
  final Map<CoinType, int> coinTypes;
  final int gatesHit;
  final int gatesMissed;

  @override
  State<_ScoreBreakdownCard> createState() => _ScoreBreakdownCardState();
}

class _ScoreBreakdownCardState extends State<_ScoreBreakdownCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.run;
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: r.totalScore),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, score, _) {
        return AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final slide = Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
            return SlideTransition(
              position: slide,
              child: FadeTransition(
                opacity: _c,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$score',
                        style: const TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          height: 1,
                          color: AppColors.gold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Total score',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _row('Peak multiplier', '${r.maxMultiplier}x'),
                      _row('STREETBEAT ×', '${r.streetbeatCount}'),
                      _row(
                        'Gates',
                        '${widget.gatesHit} hit · ${widget.gatesMissed} missed',
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Coins by type',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.coinTypes.entries
                            .map(
                              (e) => Chip(
                                label: Text(
                                  '${e.key.name}: ${e.value}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: AppColors.card,
                                side: BorderSide.none,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _row(String a, String b) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(a, style: const TextStyle(color: AppColors.textSecondary)),
          Text(b, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _GhostSection extends StatelessWidget {
  const _GhostSection({required this.payload});

  final RunSummaryPayload payload;

  @override
  Widget build(BuildContext context) {
    final r = payload.run;
    final delta = r.ghostDelta;
    final ahead = delta >= 0;
    final text = ahead
        ? 'You finished ${delta.abs().toStringAsFixed(1)}s ahead of your ghost.'
        : 'You were ${delta.abs().toStringAsFixed(1)}s behind your ghost.';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.ghostBlue.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt_rounded, color: AppColors.ghostBlue, size: 22),
              SizedBox(width: 8),
              Text(
                'Ghost comparison',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: _PaceComparisonChart(payload: payload),
          ),
        ],
      ),
    );
  }
}

class _PaceComparisonChart extends StatelessWidget {
  const _PaceComparisonChart({required this.payload});

  final RunSummaryPayload payload;

  @override
  Widget build(BuildContext context) {
    final p = payload.playerPaceSamples;
    final g = payload.ghostPaceSamples;
    if (p.isEmpty && g.isEmpty) {
      return const Center(child: Text('Not enough pace samples'));
    }
    final maxD = [
      ...p.map((e) => e.distanceMeters),
      ...g.map((e) => e.distanceMeters),
    ].fold<double>(0, math.max);
    final maxKm = (maxD / 1000).clamp(0.1, 1e9);

    List<FlSpot> spots(List<PaceSample> s) {
      final list = s
          .map(
            (e) => FlSpot(
              (e.distanceMeters / 1000).clamp(0.0, maxKm),
              (e.paceSecPerKm / 60).clamp(2.0, 30.0),
            ),
          )
          .toList();
      list.sort((a, b) => a.x.compareTo(b.x));
      return list;
    }

    final spotsP = spots(p);
    final spotsG = spots(g);

    var minY = 30.0;
    var maxY = 4.0;
    for (final s in [...spotsP, ...spotsG]) {
      minY = math.min(minY, s.y);
      maxY = math.max(maxY, s.y);
    }
    if (maxY <= minY) {
      maxY = minY + 1;
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxKm,
        minY: minY - 0.5,
        maxY: maxY + 0.5,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.white.withValues(alpha: 0.06),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, m) => Text(
                '${v.round()}′',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (v, m) => Text(
                '${v.toStringAsFixed(1)} km',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          if (spotsG.isNotEmpty)
            LineChartBarData(
              spots: spotsG,
              color: AppColors.ghostBlue,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
            ),
          if (spotsP.isNotEmpty)
            LineChartBarData(
              spots: spotsP,
              color: AppColors.primary,
              barWidth: 3,
              dotData: const FlDotData(show: false),
            ),
        ],
        lineTouchData: const LineTouchData(enabled: false),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({
    required this.payload,
    required this.flameAnimation,
  });

  final RunSummaryPayload payload;
  final Animation<double> flameAnimation;

  @override
  Widget build(BuildContext context) {
    final p = payload;
    final filled = p.runsThisWeekAfterRun.clamp(0, 7);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: flameAnimation,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _FlamePainter(
                      t: flameAnimation.value,
                    ),
                    size: const Size(28, 34),
                  );
                },
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Week ${p.currentStreakWeeks} of your streak',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      '${p.runsThisWeekAfterRun}/${p.weeklyGoalRuns} runs this week',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final active = i < filled;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: active ? AppColors.primary : AppColors.card,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('M', style: TextStyle(fontSize: 10)),
              Text('T', style: TextStyle(fontSize: 10)),
              Text('W', style: TextStyle(fontSize: 10)),
              Text('T', style: TextStyle(fontSize: 10)),
              Text('F', style: TextStyle(fontSize: 10)),
              Text('S', style: TextStyle(fontSize: 10)),
              Text('S', style: TextStyle(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FlamePainter extends CustomPainter {
  _FlamePainter({required this.t});

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final h = 1 + 0.12 * (t * 2 - 1);
    final path = Path()
      ..moveTo(size.width * 0.5, 0)
      ..quadraticBezierTo(
        size.width * 1.1,
        size.height * 0.45 * h,
        size.width * 0.5,
        size.height,
      )
      ..quadraticBezierTo(
        -size.width * 0.1,
        size.height * 0.45 * h,
        size.width * 0.5,
        0,
      );
    final fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFE082),
          AppColors.primary,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path, fill);
  }

  @override
  bool shouldRepaint(covariant _FlamePainter oldDelegate) => oldDelegate.t != t;
}

class _BadgesSection extends StatelessWidget {
  const _BadgesSection({
    required this.badges,
    required this.shimmer,
  });

  final List<BadgeModel> badges;
  final Animation<double> shimmer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Badges earned',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        const SizedBox(height: 10),
        ...badges.map((b) => _BadgeTile(badge: b, shimmer: shimmer)),
      ],
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge, required this.shimmer});

  final BadgeModel badge;
  final Animation<double> shimmer;

  @override
  Widget build(BuildContext context) {
    final def = kBadgeById[badge.id];
    final title = def?.name ?? badge.id;
    final subtitle = def?.description ?? 'New achievement unlocked.';
    final emoji = def?.icon ?? '🏅';
    return TweenAnimationBuilder<Offset>(
      tween: Tween(begin: const Offset(0, 0.15), end: Offset.zero),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, off, child) {
        return Transform.translate(
          offset: Offset(0, off.dy * 40),
          child: Opacity(
            opacity: 1 - off.dy / 0.15,
            child: child,
          ),
        );
      },
      child: AnimatedBuilder(
        animation: shimmer,
        builder: (context, _) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) {
                final shift = shimmer.value * 2 - 1;
                return LinearGradient(
                  colors: [
                    AppColors.gold.withValues(alpha: 0.35),
                    Colors.white,
                    AppColors.gold.withValues(alpha: 0.35),
                  ],
                  stops: const [0.35, 0.5, 0.65],
                  begin: Alignment(-1.5 + shift, 0),
                  end: Alignment(1.5 + shift, 0),
                ).createShader(bounds);
              },
              child: Row(
                children: [
                  Text(
                    emoji,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TomorrowHookCard extends StatelessWidget {
  const _TomorrowHookCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.2),
            AppColors.card,
          ],
        ),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.sharing,
    required this.onShare,
    required this.onDone,
  });

  final bool sharing;
  final VoidCallback onShare;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: sharing ? null : onShare,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: sharing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(Icons.ios_share_rounded),
            label: Text(sharing ? 'Sharing…' : 'Share'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: onDone,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textPrimary,
              minimumSize: const Size.fromHeight(52),
            ),
            child: const Text('Done'),
          ),
        ),
      ],
    );
  }
}

class _ShareCard extends StatelessWidget {
  const _ShareCard({required this.payload});

  final RunSummaryPayload payload;

  @override
  Widget build(BuildContext context) {
    final r = payload.run;
    return SizedBox(
      width: 360,
      height: 480,
      child: Material(
        color: AppColors.background,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        const Icon(Icons.directions_run, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'StreetBeat',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                LocationUtils.formatDistance(r.distance),
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${r.totalScore} pts · ${r.maxMultiplier}x peak',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                r.averagePace ?? '—',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
