import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../../../core/utils/location_utils.dart';
import '../models/coin_model.dart';
import '../models/ghost_model.dart';

String segmentKeyForPaths(List<List<LatLng>> paths) {
  if (paths.isEmpty) {
    return 'default';
  }
  final seg = paths.first;
  if (seg.length < 2) {
    return '${seg.first.latitude.toStringAsFixed(3)}_${seg.first.longitude.toStringAsFixed(3)}';
  }
  final a = seg.first;
  final b = seg[1];
  return '${a.latitude.toStringAsFixed(3)}_${a.longitude.toStringAsFixed(3)}__${b.latitude.toStringAsFixed(3)}_${b.longitude.toStringAsFixed(3)}';
}

double dropOneMultiplierTier(double multiplier) {
  const order = [10.0, 5.0, 3.0, 2.0, 1.5, 1.0];
  for (final t in order) {
    if (multiplier > t + 1e-3) {
      return t;
    }
  }
  return 1.0;
}

CoinType rollCoinType(math.Random rng) {
  final r = rng.nextDouble();
  if (r < 0.6) {
    return CoinType.standard;
  }
  if (r < 0.85) {
    return CoinType.explorer;
  }
  if (r < 0.95) {
    return CoinType.elevation;
  }
  if (r < 0.98) {
    return CoinType.consistency;
  }
  return CoinType.goal;
}

double ghostDeltaSeconds({
  required GhostModel? ghost,
  required int elapsedMs,
  required double playerDistance,
  required double playerSpeed,
}) {
  if (ghost == null || ghost.points.isEmpty) {
    return 0;
  }
  final gDist = ghostDistanceAtElapsed(ghost, elapsedMs);
  final diffM = playerDistance - gDist;
  final spd = playerSpeed.clamp(0.5, 6.0);
  return diffM / spd;
}

bool playerAheadOfGhost(
    GhostModel? ghost, int elapsedMs, double playerDistance) {
  if (ghost == null || ghost.points.isEmpty) {
    return false;
  }
  return playerDistance > ghostDistanceAtElapsed(ghost, elapsedMs) + 2;
}

bool ghostAheadOfPlayer(
    GhostModel? ghost, int elapsedMs, double playerDistance) {
  if (ghost == null || ghost.points.isEmpty) {
    return false;
  }
  return ghostDistanceAtElapsed(ghost, elapsedMs) > playerDistance + 2;
}

double bearingAlongNearestPath(
    LatLng p, List<List<LatLng>> paths, math.Random rng) {
  if (paths.isEmpty) {
    return rng.nextDouble() * 360;
  }
  double bestD = 1e18;
  LatLng? a;
  LatLng? b;
  for (final seg in paths) {
    if (seg.length < 2) {
      continue;
    }
    for (var i = 0; i < seg.length - 1; i++) {
      final d = LocationUtils.distanceToSegmentMeters(seg[i], seg[i + 1], p);
      if (d < bestD) {
        bestD = d;
        a = seg[i];
        b = seg[i + 1];
      }
    }
  }
  if (a == null || b == null) {
    return rng.nextDouble() * 360;
  }
  var brg = LocationUtils.bearing(a, b);
  brg += (rng.nextDouble() * 20 - 10);
  return (brg + 360) % 360;
}

GhostModel ghostFromRoute({
  required String runId,
  required List<LatLng> route,
  required int durationMs,
  required double totalDistance,
}) {
  if (route.isEmpty) {
    return GhostModel(runId: runId, points: const <GhostPoint>[]);
  }
  final pts = <GhostPoint>[];
  var acc = 0.0;
  final dist = totalDistance <= 0 ? 1.0 : totalDistance;
  for (var i = 0; i < route.length; i++) {
    if (i > 0) {
      acc += LocationUtils.distanceMeters(route[i - 1], route[i]);
    }
    final t = (durationMs * (acc / dist)).round().clamp(0, durationMs);
    pts.add(
      GhostPoint(
        position: route[i],
        timestampMs: t,
        distanceFromStart: acc,
      ),
    );
  }
  return GhostModel(runId: runId, points: pts);
}
