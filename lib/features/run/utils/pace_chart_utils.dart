import 'package:latlong2/latlong.dart';

import '../../../core/utils/location_utils.dart';
import '../models/ghost_model.dart';
import '../models/run_summary_payload.dart';

List<PaceSample> paceSamplesFromRoute(
  List<LatLng> route,
  int durationSeconds,
  double totalDistanceMeters,
) {
  if (route.length < 2 || durationSeconds <= 0 || totalDistanceMeters < 5) {
    return [];
  }
  final out = <PaceSample>[];
  var cum = 0.0;
  var prevFrac = 0.0;
  for (var i = 1; i < route.length; i++) {
    final seg = LocationUtils.distanceMeters(route[i - 1], route[i]);
    cum += seg;
    final frac = (cum / totalDistanceMeters).clamp(0.0, 1.0);
    final dt = (frac - prevFrac) * durationSeconds;
    prevFrac = frac;
    if (seg > 0.5 && dt > 0.05) {
      final mps = seg / dt;
      if (mps > 0.3 && mps < 12) {
        final spk = 1000.0 / mps;
        if (spk < 2400) {
          out.add(PaceSample(cum, spk));
        }
      }
    }
  }
  return out;
}

List<PaceSample> paceSamplesFromGhost(GhostModel ghost) {
  if (ghost.points.length < 2) {
    return [];
  }
  final out = <PaceSample>[];
  for (var i = 1; i < ghost.points.length; i++) {
    final a = ghost.points[i - 1];
    final b = ghost.points[i];
    final dd = b.distanceFromStart - a.distanceFromStart;
    final dt = (b.timestampMs - a.timestampMs) / 1000.0;
    if (dd > 0.5 && dt > 0.05) {
      final mps = dd / dt;
      if (mps > 0.3 && mps < 12) {
        final spk = 1000.0 / mps;
        if (spk < 2400) {
          out.add(PaceSample(b.distanceFromStart, spk));
        }
      }
    }
  }
  return out;
}
