import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/utils/location_utils.dart';
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
  static const _stadiaDark =
      'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}.png';

  @override
  void initState() {
    super.initState();
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
    return RepaintBoundary(
      child: FlutterMap(
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
            urlTemplate: _stadiaDark,
            userAgentPackageName: 'com.streetbeat.streetbeat',
            maxZoom: 20,
          ),
          const RichAttributionWidget(
            attributions: [
              TextSourceAttribution(
                'Stadia Maps, OpenMapTiles, OpenStreetMap contributors',
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
