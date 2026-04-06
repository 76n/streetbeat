import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/map_tiles.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/location_utils.dart';
import '../../../../core/utils/map_tile_network.dart';
import '../../models/coin_model.dart';
import '../../models/gate_model.dart';

class RunMapLayer extends StatefulWidget {
  const RunMapLayer({
    super.key,
    required this.mapController,
    required this.player,
    required this.bearingDeg,
    required this.path,
    required this.coins,
    required this.gates,
    required this.ghostPastPath,
    required this.ghostAheadPath,
    required this.ghostMarker,
    required this.ghostMarkerOpacity,
    required this.playerSpeedMps,
    required this.pulsePhase,
    required this.streetbeatActive,
  });

  final MapController mapController;
  final LatLng player;
  final double bearingDeg;
  final List<LatLng> path;
  final List<CoinModel> coins;
  final List<GateModel> gates;
  final List<LatLng> ghostPastPath;
  final List<LatLng> ghostAheadPath;
  final LatLng? ghostMarker;
  final double ghostMarkerOpacity;
  final double playerSpeedMps;
  final double pulsePhase;
  final bool streetbeatActive;

  @override
  State<RunMapLayer> createState() => _RunMapLayerState();
}

class _RunMapLayerState extends State<RunMapLayer> {
  bool _checkingNet = true;
  bool _netOk = false;
  bool _tilesFailed = false;
  int _tileErrorCount = 0;
  int _layerGeneration = 0;
  bool _tilesLoadingOverlay = true;

  @override
  void initState() {
    super.initState();
    _verifyInternet();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      widget.mapController.moveAndRotate(
        widget.player,
        17,
        -widget.bearingDeg,
      );
    });
  }

  @override
  void didUpdateWidget(covariant RunMapLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.player != widget.player ||
        (oldWidget.bearingDeg - widget.bearingDeg).abs() > 0.2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        widget.mapController.moveAndRotate(
          widget.player,
          widget.mapController.camera.zoom,
          -widget.bearingDeg,
        );
      });
    }
  }

  Future<void> _verifyInternet() async {
    setState(() {
      _checkingNet = true;
    });
    final ok = await mapTilesReachable();
    if (!mounted) {
      return;
    }
    setState(() {
      _checkingNet = false;
      _netOk = ok;
    });
    if (ok) {
      _scheduleHideLoadingOverlay();
    }
  }

  void _scheduleHideLoadingOverlay() {
    Future<void>.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() => _tilesLoadingOverlay = false);
      }
    });
  }

  void _onTileError(TileImage _, Object __, StackTrace? ___) {
    _tileErrorCount++;
    if (_tileErrorCount >= 8 && mounted) {
      setState(() {
        _tilesFailed = true;
        _tilesLoadingOverlay = false;
      });
    }
  }

  void _retryTiles() {
    setState(() {
      _tilesFailed = false;
      _tileErrorCount = 0;
      _layerGeneration++;
      _tilesLoadingOverlay = true;
    });
    _scheduleHideLoadingOverlay();
  }

  bool _gateLooksCapturable(GateModel g) {
    final d = LocationUtils.distanceMeters(widget.player, g.position);
    if (d > 14 || widget.playerSpeedMps < 0.9) {
      return false;
    }
    return LocationUtils.angleDiffDeg(widget.bearingDeg, g.direction).abs() <=
        35;
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingNet) {
      return const ColoredBox(
        color: AppColors.background,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                'Checking connection…',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (!_netOk) {
      return ColoredBox(
        color: AppColors.background,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 48,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Map needs internet',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Connect to load map tiles, then try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _verifyInternet,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: FlutterMap(
            key: ValueKey(_layerGeneration),
            mapController: widget.mapController,
            options: MapOptions(
              initialCenter: widget.player,
              initialZoom: 17,
              initialRotation: 0,
              minZoom: 5,
              maxZoom: 20,
              backgroundColor: AppColors.background,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
              ),
            ),
            children: [
              TileLayer(
                key: ValueKey('tl_$_layerGeneration'),
                urlTemplate: MapTiles.primary,
                fallbackUrl: MapTiles.fallback,
                userAgentPackageName: MapTiles.userAgentPackageName,
                maxZoom: 20,
                maxNativeZoom: 19,
                subdomains: const [],
                errorTileCallback: _onTileError,
              ),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    '© OpenStreetMap contributors · HOT',
                    prependCopyright: false,
                  ),
                ],
              ),
              if (widget.path.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: widget.path,
                      strokeWidth: 4,
                      color: AppColors.primary.withValues(alpha: 0.35),
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                  ],
                ),
              if (widget.ghostPastPath.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: widget.ghostPastPath,
                      strokeWidth: 3,
                      color: AppColors.ghostBlue.withValues(alpha: 0.45),
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                  ],
                ),
              if (widget.ghostAheadPath.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: widget.ghostAheadPath,
                      strokeWidth: 3,
                      color: AppColors.ghostBlue.withValues(alpha: 0.55),
                      isDotted: true,
                      strokeCap: StrokeCap.round,
                    ),
                  ],
                ),
              MarkerLayer(
                rotate: true,
                markers: [
                  for (final c in widget.coins)
                    if (!c.isCollected)
                      Marker(
                        key: ValueKey(c.id),
                        point: c.position,
                        width: 44,
                        height: 44,
                        child: RepaintBoundary(
                          child: _PulsingCoinMarker(
                            type: c.type,
                            phase: widget.pulsePhase,
                            cascade: widget.streetbeatActive,
                            seed: c.id.hashCode,
                          ),
                        ),
                      ),
                ],
              ),
              MarkerLayer(
                markers: [
                  for (final g in widget.gates)
                    if (!g.isCapture && !g.isMissed)
                      Marker(
                        key: ValueKey(g.id),
                        point: g.position,
                        width: 56,
                        height: 48,
                        rotate: false,
                        alignment: Alignment.center,
                        child: RepaintBoundary(
                          child: _GateMarker(
                            directionDeg: g.direction,
                            capturable: _gateLooksCapturable(g),
                          ),
                        ),
                      ),
                ],
              ),
              MarkerLayer(
                rotate: true,
                markers: [
                  if (widget.ghostMarker != null)
                    Marker(
                      point: widget.ghostMarker!,
                      width: 28,
                      height: 28,
                      child: RepaintBoundary(
                        child: _GhostDot(opacity: widget.ghostMarkerOpacity),
                      ),
                    ),
                  Marker(
                    point: widget.player,
                    width: 56,
                    height: 56,
                    child: const RepaintBoundary(child: _PlayerMarker()),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_tilesLoadingOverlay && !_tilesFailed)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: AppColors.background.withValues(alpha: 0.35),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 12),
                      Text(
                        'Loading map…',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (_tilesFailed)
          Positioned.fill(
            child: ColoredBox(
              color: AppColors.background.withValues(alpha: 0.88),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.map_outlined,
                        size: 44,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Could not load map tiles',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _retryTiles,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text('Retry map'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PlayerMarker extends StatelessWidget {
  const _PlayerMarker();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.55),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        Positioned(
          top: 2,
          child: Icon(
            Icons.navigation_rounded,
            color: Colors.white.withValues(alpha: 0.95),
            size: 18,
          ),
        ),
      ],
    );
  }
}

class _GhostDot extends StatelessWidget {
  const _GhostDot({required this.opacity});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.ghostBlue.withValues(alpha: opacity * 0.45),
        border: Border.all(
          color: AppColors.ghostBlue.withValues(alpha: opacity * 0.9),
          width: 2,
        ),
      ),
    );
  }
}

class _PulsingCoinMarker extends StatelessWidget {
  const _PulsingCoinMarker({
    required this.type,
    required this.phase,
    required this.cascade,
    required this.seed,
  });

  final CoinType type;
  final double phase;
  final bool cascade;
  final int seed;

  @override
  Widget build(BuildContext context) {
    final pulse = 0.88 + 0.12 * math.sin(phase * math.pi * 2 + seed * 0.01);
    final cascadeY =
        cascade ? 6 * math.sin(phase * math.pi * 2 + seed * 0.7) : 0.0;
    return Transform.translate(
      offset: Offset(0, cascadeY),
      child: Transform.scale(
        scale: pulse,
        child: CustomPaint(
          painter: _CoinDiscPainter(colors: _coinColors(type)),
          size: const Size(36, 36),
        ),
      ),
    );
  }

  List<Color> _coinColors(CoinType t) {
    return switch (t) {
      CoinType.standard => [
          const Color(0xFFFFD54F),
          const Color(0xFFFFA000),
        ],
      CoinType.explorer => [
          const Color(0xFFE0E0E0),
          const Color(0xFF9E9E9E),
        ],
      CoinType.elevation => [
          const Color(0xFF64B5F6),
          const Color(0xFF1976D2),
        ],
      CoinType.phantomGold => [
          const Color(0xFFFF6B9D),
          const Color(0xFFFFD700),
          const Color(0xFF00E5FF),
        ],
      CoinType.milestone => [
          const Color(0xFFFFE082),
          const Color(0xFFFF8F00),
        ],
      CoinType.consistency => [
          const Color(0xFFCE93D8),
          const Color(0xFF7B1FA2),
        ],
      CoinType.goal => [
          const Color(0xFF81C784),
          const Color(0xFF2E7D32),
        ],
      CoinType.personalBest => [
          const Color(0xFF4DD0E1),
          const Color(0xFF00838F),
        ],
    };
  }
}

class _CoinDiscPainter extends CustomPainter {
  _CoinDiscPainter({required this.colors});

  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 2;
    final shader = RadialGradient(
      colors: colors.length >= 3
          ? colors
          : [
              colors.first.withValues(alpha: 0.95),
              colors.last,
            ],
    ).createShader(Rect.fromCircle(center: c, radius: r));
    final fill = Paint()..shader = shader;
    canvas.drawCircle(c, r, fill);
    final border = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(c, r - 1, border);
  }

  @override
  bool shouldRepaint(covariant _CoinDiscPainter oldDelegate) =>
      oldDelegate.colors != colors;
}

class _GateMarker extends StatelessWidget {
  const _GateMarker({
    required this.directionDeg,
    required this.capturable,
  });

  final double directionDeg;
  final bool capturable;

  @override
  Widget build(BuildContext context) {
    final post =
        capturable ? AppColors.success : Colors.white.withValues(alpha: 0.85);
    final arrow = capturable ? AppColors.success : Colors.white;
    return Transform.rotate(
      angle: directionDeg * math.pi / 180,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 5,
            height: 28,
            decoration: BoxDecoration(
              color: post,
              borderRadius: BorderRadius.circular(2),
              boxShadow: capturable
                  ? [
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.45),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.arrow_forward_rounded,
              color: arrow,
              size: 22,
            ),
          ),
          Container(
            width: 5,
            height: 28,
            decoration: BoxDecoration(
              color: post,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
