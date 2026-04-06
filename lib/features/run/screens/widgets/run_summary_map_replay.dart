import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/map_tiles.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/location_utils.dart';
import '../../models/coin_model.dart';
import '../../models/gate_model.dart';

List<LatLng> trimRouteByProgress(List<LatLng> path, double t) {
  if (path.length < 2) {
    return List<LatLng>.from(path);
  }
  var total = 0.0;
  final segLen = <double>[];
  for (var i = 1; i < path.length; i++) {
    segLen.add(LocationUtils.distanceMeters(path[i - 1], path[i]));
    total += segLen[i - 1];
  }
  if (total <= 1) {
    return List<LatLng>.from(path);
  }
  final target = total * t.clamp(0.0, 1.0);
  var acc = 0.0;
  final out = <LatLng>[path.first];
  for (var i = 0; i < segLen.length; i++) {
    if (acc + segLen[i] >= target) {
      final over = target - acc;
      final ratio = segLen[i] > 0 ? over / segLen[i] : 1.0;
      final a = path[i];
      final b = path[i + 1];
      out.add(
        LatLng(
          a.latitude + ratio * (b.latitude - a.latitude),
          a.longitude + ratio * (b.longitude - a.longitude),
        ),
      );
      break;
    }
    acc += segLen[i];
    out.add(path[i + 1]);
  }
  return out;
}

LatLngBounds? boundsForPoints(Iterable<LatLng> points) {
  final list = points.toList();
  if (list.isEmpty) {
    return null;
  }
  return LatLngBounds.fromPoints(list);
}

Color coinColor(CoinType t) {
  return switch (t) {
    CoinType.standard => const Color(0xFFFFD54F),
    CoinType.explorer => const Color(0xFFBDBDBD),
    CoinType.elevation => const Color(0xFF64B5F6),
    CoinType.phantomGold => const Color(0xFFFFD700),
    CoinType.milestone => const Color(0xFFFF8F00),
    CoinType.consistency => const Color(0xFFCE93D8),
    CoinType.goal => const Color(0xFF81C784),
    CoinType.personalBest => const Color(0xFF4DD0E1),
  };
}

class RunSummaryMapReplay extends StatefulWidget {
  const RunSummaryMapReplay({
    super.key,
    required this.route,
    required this.ghostRoute,
    required this.coins,
    required this.gates,
  });

  final List<LatLng> route;
  final List<LatLng> ghostRoute;
  final List<CoinModel> coins;
  final List<GateModel> gates;

  @override
  State<RunSummaryMapReplay> createState() => _RunSummaryMapReplayState();
}

class _RunSummaryMapReplayState extends State<RunSummaryMapReplay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _draw;

  @override
  void initState() {
    super.initState();
    _draw = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();
  }

  @override
  void dispose() {
    _draw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height * 0.38;
    final allPts = <LatLng>[
      ...widget.route,
      ...widget.ghostRoute,
    ];
    final bounds = boundsForPoints(allPts.isNotEmpty ? allPts : widget.route);
    final fit = bounds != null
        ? CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(36))
        : null;

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: h.clamp(220, 420),
          child: FlutterMap(
            options: MapOptions(
              initialCameraFit: fit,
              initialCenter: widget.route.isNotEmpty
                  ? widget.route.first
                  : const LatLng(0, 0),
              initialZoom: 14,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
              ),
              backgroundColor: AppColors.background,
            ),
            children: [
              TileLayer(
                urlTemplate: MapTiles.primary,
                fallbackUrl: MapTiles.fallback,
                userAgentPackageName: MapTiles.userAgentPackageName,
                maxZoom: 20,
                maxNativeZoom: 19,
                subdomains: const [],
              ),
              if (widget.ghostRoute.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: widget.ghostRoute,
                      strokeWidth: 3,
                      color: AppColors.ghostBlue.withValues(alpha: 0.55),
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                  ],
                ),
              AnimatedBuilder(
                animation: _draw,
                builder: (context, _) {
                  final t = Curves.easeInOut.transform(_draw.value);
                  final playerSeg = trimRouteByProgress(widget.route, t);
                  if (playerSeg.length < 2) {
                    return const PolylineLayer(polylines: []);
                  }
                  return PolylineLayer(
                    polylines: [
                      Polyline(
                        points: playerSeg,
                        strokeWidth: 4,
                        color: AppColors.primary.withValues(alpha: 0.9),
                        strokeCap: StrokeCap.round,
                        strokeJoin: StrokeJoin.round,
                      ),
                    ],
                  );
                },
              ),
              MarkerLayer(
                markers: [
                  for (final c in widget.coins.where((e) => e.isCollected))
                    Marker(
                      point: c.position,
                      width: 14,
                      height: 14,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: coinColor(c.type),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.7),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: coinColor(c.type).withValues(alpha: 0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  for (final g in widget.gates.where((e) => e.isCapture))
                    Marker(
                      point: g.position,
                      width: 22,
                      height: 22,
                      child: const Icon(
                        Icons.flag_rounded,
                        color: AppColors.success,
                        size: 20,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
