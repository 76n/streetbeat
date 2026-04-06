import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/location_utils.dart';
import '../../../shared/services/location_service.dart';
import '../bloc/run_bloc.dart';
import '../bloc/run_event.dart' as re;
import '../bloc/run_state.dart';
import '../models/coin_model.dart';
import '../utils/ghost_map_utils.dart';
import 'widgets/run_hud_overlay.dart';
import 'widgets/run_map_layer.dart';

class RunScreen extends StatelessWidget {
  const RunScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<RunBloc>(),
      child: const _RunSessionView(),
    );
  }
}

class _RunSessionView extends StatefulWidget {
  const _RunSessionView();

  @override
  State<_RunSessionView> createState() => _RunSessionState();
}

class _RunSessionState extends State<_RunSessionView>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final GlobalKey _scoreKey = GlobalKey();
  StreamSubscription<LocationSessionSnapshot>? _locSub;
  LocationSessionSnapshot? _snap;
  String? _locationError;
  bool _runDispatched = false;
  bool _showGhostTrail = true;
  RunState? _prevBlocState;

  DateTime? _pauseStarted;
  Duration _pausedTotal = Duration.zero;

  late final AnimationController _coinPulse;
  late final AnimationController _multiplierBump;
  late final AnimationController _scoreBounce;
  late final AnimationController _bannerCtrl;

  double _scoreScale = 1;
  String? _bannerText;
  Color? _bannerTint;

  final List<_FlyingCoin> _flyingCoins = [];
  final List<_GateRipple> _gateRipples = [];

  @override
  void initState() {
    super.initState();
    _coinPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _multiplierBump = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _scoreBounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _bannerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _scoreBounce.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _scoreBounce.reverse();
      }
    });
    _scoreBounce.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _multiplierBump.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _multiplierBump.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _multiplierBump.reset();
      }
    });
    _bannerCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        setState(() {
          _bannerText = null;
          _bannerTint = null;
        });
        _bannerCtrl.reset();
        final st = context.read<RunBloc>().state;
        if (st is RunActive && st.celebration != null) {
          context.read<RunBloc>().add(const re.RunCelebrationAcknowledged());
        }
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _startLocation());
  }

  Future<void> _startLocation() async {
    await _locSub?.cancel();
    _locSub = null;
    setState(() => _locationError = null);
    try {
      await sl<LocationService>().requestPermissionsOnFirstRun();
    } on LocationServiceException catch (e) {
      if (mounted) {
        setState(() => _locationError = e.message);
      }
      return;
    } catch (e) {
      if (mounted) {
        setState(() => _locationError = '$e');
      }
      return;
    }

    try {
      final stream = sl<LocationService>().watchSession();
      _locSub = stream.listen(
        (s) {
          if (!mounted) {
            return;
          }
          final bloc = context.read<RunBloc>();
          if (!_runDispatched) {
            bloc.add(
              re.RunStarted(
                position: s.position,
                bearing: s.bearingDegrees,
              ),
            );
            _runDispatched = true;
          }
          bloc.add(
            re.LocationUpdated(
              position: s.position,
              speed: s.speedMetersPerSecond,
              bearing: s.bearingDegrees,
              activity: s.activity,
              distanceTraveled: s.distanceTraveledMeters,
              routeCompressed: s.compressedRecordedPath,
            ),
          );
          setState(() {
            _snap = s;
            _locationError = null;
          });
        },
        onError: (Object e) {
          if (!mounted) {
            return;
          }
          setState(() => _locationError = '$e');
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _locationError = '$e');
      }
    }
  }

  @override
  void dispose() {
    _locSub?.cancel();
    _coinPulse.dispose();
    _multiplierBump.dispose();
    _scoreBounce.dispose();
    _bannerCtrl.dispose();
    super.dispose();
  }

  int _elapsedMs(RunSessionData d) {
    final start = d.run.startedAt;
    var ms = DateTime.now().difference(start).inMilliseconds -
        _pausedTotal.inMilliseconds;
    if (_pauseStarted != null) {
      ms -= DateTime.now().difference(_pauseStarted!).inMilliseconds;
    }
    return ms.clamp(0, 1 << 30);
  }

  void _onBlocChanges(BuildContext context, RunState state) {
    final prev = _prevBlocState;
    _prevBlocState = state;

    if (state is RunPaused && prev is RunActive) {
      _pauseStarted = DateTime.now();
    }
    if (state is RunActive && prev is RunPaused && _pauseStarted != null) {
      _pausedTotal += DateTime.now().difference(_pauseStarted!);
      _pauseStarted = null;
    }

    if (state is! RunActive || prev is! RunActive) {
      if (state is RunCompleted) {
        if (context.mounted) {
          context.pushReplacement('/run-summary', extra: state.payload);
        }
      }
      return;
    }

    final wasSb = prev.data.streetbeatActive;
    if (!wasSb && state.data.streetbeatActive) {
      HapticFeedback.mediumImpact();
      unawaited(SystemSound.play(SystemSoundType.click));
    }

    if (prev.data.multiplier < state.data.multiplier) {
      _multiplierBump.forward(from: 0);
    }

    if (prev.data.run.totalScore < state.data.run.totalScore) {
      HapticFeedback.lightImpact();
      _scoreBounce.forward(from: 0);
    }

    for (final c in state.data.coins) {
      if (!c.isCollected) {
        continue;
      }
      CoinModel? before;
      for (final x in prev.data.coins) {
        if (x.id == c.id) {
          before = x;
          break;
        }
      }
      if (before != null && !before.isCollected && mounted) {
        _spawnFlyingCoin(before);
      }
    }

    final prevGates = {for (final g in prev.data.gates) g.id: g.isCapture};
    for (final g in state.data.gates) {
      if (g.isCapture && prevGates[g.id] != true) {
        HapticFeedback.lightImpact();
        _spawnGateRipple(g.position, g.points);
      }
    }

    final cel = state.celebration;
    if (cel != null) {
      switch (cel) {
        case RunCelebrationKind.playerPassedGhost:
          _flashAndBanner('👻 Ghost beaten!', AppColors.gold);
        case RunCelebrationKind.ghostPassedPlayer:
          _flashAndBanner('👻 Ghost ahead', Colors.redAccent);
        case RunCelebrationKind.objectiveComplete:
          _flashAndBanner('Objective complete!', AppColors.success);
      }
    }
  }

  void _flashAndBanner(String text, Color tint) {
    setState(() {
      _bannerText = text;
      _bannerTint = tint;
    });
    _bannerCtrl.forward(from: 0);
    HapticFeedback.mediumImpact();
  }

  void _spawnFlyingCoin(CoinModel coin) {
    try {
      final cam = _mapController.camera;
      final p = cam.latLngToScreenPoint(coin.position);
      final endBox = _scoreKey.currentContext?.findRenderObject() as RenderBox?;
      if (endBox == null || !endBox.hasSize) {
        return;
      }
      final endGlobal = endBox.localToGlobal(Offset.zero);
      final start = Offset(p.x, p.y);
      final end =
          endGlobal + Offset(endBox.size.width / 2, endBox.size.height / 2);
      final id = Object();
      final fly = _FlyingCoin(id: id, start: start, end: end);
      final c = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 520),
      );
      fly.controller = c;
      c.addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
      _flyingCoins.add(fly);
      setState(() {});
      c.forward().whenComplete(() {
        c.dispose();
        _flyingCoins.removeWhere((e) => e.id == id);
        if (mounted) {
          setState(() {});
        }
      });
    } catch (_) {}
  }

  void _spawnGateRipple(LatLng position, int gatePoints) {
    try {
      final cam = _mapController.camera;
      final p = cam.latLngToScreenPoint(position);
      final id = Object();
      final c = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 700),
      );
      _gateRipples.add(
        _GateRipple(
          id: id,
          center: Offset(p.x, p.y),
          controller: c,
          score: gatePoints,
        ),
      );
      c.addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
      setState(() {});
      c.forward().whenComplete(() {
        c.dispose();
        _gateRipples.removeWhere((e) => e.id == id);
        if (mounted) {
          setState(() {});
        }
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RunBloc, RunState>(
      listener: _onBlocChanges,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocBuilder<RunBloc, RunState>(
          builder: (context, state) {
            if (state is RunFailure) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(state.message, textAlign: TextAlign.center),
                ),
              );
            }

            final err = _locationError;
            if (err != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_off_rounded,
                        size: 48,
                        color: AppColors.textSecondary.withValues(alpha: 0.85),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        err,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () async {
                          await Geolocator.openLocationSettings();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text('Location settings'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton( // ignore: prefer_const_constructors
                        onPressed: openAppSettings,
                        child: const Text('App settings'),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _startLocation,
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is RunIdle || _snap == null) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text('Locking GPS…'),
                  ],
                ),
              );
            }

            if (state is RunCompleted) {
              return const SizedBox.shrink();
            }

            final data = switch (state) {
              RunActive d => d.data,
              RunPaused d => d.data,
              _ => null,
            };
            if (data == null) {
              return const SizedBox.shrink();
            }

            final snap = _snap!;
            final elapsed = _elapsedMs(data);
            final ghost = data.ghost;
            final ghostPos =
                ghost != null ? ghostLatLngAtElapsed(ghost, elapsed) : null;
            final ghostPast = ghost != null && _showGhostTrail
                ? ghostTrailUpTo(ghost, elapsed)
                : <LatLng>[];
            var ghostAhead = ghost != null && _showGhostTrail
                ? ghostTrailAhead(ghost, elapsed, 45000)
                : <LatLng>[];
            if (ghostPos != null && ghostAhead.isNotEmpty) {
              ghostAhead = [ghostPos, ...ghostAhead];
            }

            final ghostNear = data.ghostDeltaSeconds.abs() <= 10;
            final ghostOpacity = ghostNear ? 1.0 : 0.48;

            final timerMs = elapsed;
            final tSec = timerMs ~/ 1000;
            final timerLabel =
                '${(tSec ~/ 3600).toString().padLeft(2, '0')}:${((tSec % 3600) ~/ 60).toString().padLeft(2, '0')}:${(tSec % 60).toString().padLeft(2, '0')}';

            double ringP = 0;
            if (data.streetbeatActive && data.streetbeatEndsAt != null) {
              final left = data.streetbeatEndsAt!.difference(DateTime.now());
              ringP = (left.inMilliseconds / 30000).clamp(0.0, 1.0);
            }

            _scoreScale =
                1 + 0.12 * Curves.easeOut.transform(_scoreBounce.value);

            return Stack(
              fit: StackFit.expand,
              children: [
                RepaintBoundary(
                  child: RunMapLayer(
                    mapController: _mapController,
                    player: snap.position,
                    bearingDeg: snap.bearingDegrees,
                    path: data.run.route,
                    coins: data.coins,
                    gates: data.gates,
                    ghostPastPath: ghostPast,
                    ghostAheadPath: ghostAhead.length >= 2 ? ghostAhead : [],
                    ghostMarker: _showGhostTrail ? ghostPos : null,
                    ghostMarkerOpacity: ghostOpacity,
                    playerSpeedMps: snap.speedMetersPerSecond,
                    pulsePhase: _coinPulse.value,
                    streetbeatActive: data.streetbeatActive,
                  ),
                ),
                if (data.streetbeatActive) const _StreetbeatGlow(),
                ..._buildFlyingCoins(),
                ..._buildGateRipples(),
                if (_bannerText != null) _buildBanner(),
                if (_bannerTint != null)
                  IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _bannerCtrl,
                      builder: (context, _) {
                        final o = (1 - _bannerCtrl.value) * 0.25;
                        return Container(
                          color: _bannerTint!.withValues(alpha: o),
                        );
                      },
                    ),
                  ),
                RunHudOverlay(
                  run: data.run,
                  distanceLabel:
                      LocationUtils.formatDistance(data.run.distance),
                  paceLabel: snap.paceFormatted,
                  timerLabel: timerLabel,
                  score: data.run.totalScore,
                  scoreKey: _scoreKey,
                  multiplier: data.multiplier,
                  streetbeatActive: data.streetbeatActive,
                  streetbeatEndsAt: data.streetbeatEndsAt,
                  multiplierPulse:
                      Curves.easeOut.transform(_multiplierBump.value),
                  ringProgress: ringP,
                  objective: data.activeObjective,
                  objectiveKey: ValueKey(
                    '${data.activeObjective.kind}_${data.activeObjective.target}_${data.activeObjective.progress}',
                  ),
                  onPause: () {
                    context.read<RunBloc>().add(const re.RunPaused());
                    RunHudOverlay.showPauseSheet(
                      context,
                      run: data.run,
                      paceLabel: snap.paceFormatted,
                      timerLabel: timerLabel,
                      onResume: () {
                        context.read<RunBloc>().add(const re.RunResumed());
                      },
                      onEndRun: () {
                        context.read<RunBloc>().add(const re.RunStopped());
                      },
                    );
                  },
                  onStop: () {
                    context.read<RunBloc>().add(const re.RunStopped());
                  },
                  ghostVisible: _showGhostTrail,
                  onGhostToggle: (v) => setState(() => _showGhostTrail = v),
                  scoreScale: _scoreScale,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildFlyingCoins() {
    return _flyingCoins.map((f) {
      final t = f.controller?.value ?? 0.0;
      final arc = math.sin(t * math.pi);
      final p = Offset.lerp(f.start, f.end, t)! + Offset(0, -80 * arc);
      return Positioned(
        left: p.dx - 14,
        top: p.dy - 14,
        child: IgnorePointer(
          child: Opacity(
            opacity: 1 - t * 0.2,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildGateRipples() {
    return _gateRipples.map((r) {
      final t = r.controller.value;
      final radius = 28 + 60 * t;
      return Positioned(
        left: r.center.dx - radius,
        top: r.center.dy - radius,
        child: IgnorePointer(
          child: Opacity(
            opacity: 1 - t,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: radius * 2,
                  height: radius * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.85),
                      width: 3,
                    ),
                  ),
                ),
                Transform.translate(
                  offset: Offset(0, -28 - 40 * t),
                  child: Transform.scale(
                    scale: 1 + 0.35 * math.sin(t * math.pi),
                    child: Text(
                      '+${r.score}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.success,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildBanner() {
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 120,
      left: 24,
      right: 24,
      child: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _bannerCtrl,
            curve: const Interval(0, 0.15, curve: Curves.easeOut),
          ),
        ),
        child: Material(
          color: AppColors.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Text(
              _bannerText ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FlyingCoin {
  _FlyingCoin({
    required this.id,
    required this.start,
    required this.end,
  });

  final Object id;
  final Offset start;
  final Offset end;
  AnimationController? controller;
}

class _GateRipple {
  _GateRipple({
    required this.id,
    required this.center,
    required this.controller,
    required this.score,
  });

  final Object id;
  final Offset center;
  final AnimationController controller;
  final int score;
}

class _StreetbeatGlow extends StatelessWidget {
  const _StreetbeatGlow();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.05,
              colors: [
                Colors.transparent,
                AppColors.gold.withValues(alpha: 0.08),
              ],
            ),
            border: Border.all(
              width: 3,
              color: AppColors.gold.withValues(alpha: 0.35),
            ),
          ),
        ),
      ),
    );
  }
}
