import 'package:latlong2/latlong.dart';

import '../models/ghost_model.dart';

LatLng? ghostLatLngAtElapsed(GhostModel ghost, int elapsedMs) {
  if (ghost.points.isEmpty) {
    return null;
  }
  if (elapsedMs <= ghost.points.first.timestampMs) {
    return ghost.points.first.position;
  }
  if (elapsedMs >= ghost.points.last.timestampMs) {
    return ghost.points.last.position;
  }
  for (var i = 0; i < ghost.points.length - 1; i++) {
    final a = ghost.points[i];
    final b = ghost.points[i + 1];
    if (elapsedMs >= a.timestampMs && elapsedMs <= b.timestampMs) {
      final span = b.timestampMs - a.timestampMs;
      if (span <= 0) {
        return b.position;
      }
      final t = (elapsedMs - a.timestampMs) / span;
      return LatLng(
        a.position.latitude + t * (b.position.latitude - a.position.latitude),
        a.position.longitude +
            t * (b.position.longitude - a.position.longitude),
      );
    }
  }
  return ghost.points.last.position;
}

List<LatLng> ghostTrailUpTo(GhostModel ghost, int elapsedMs) {
  if (ghost.points.isEmpty) {
    return [];
  }
  final out = <LatLng>[];
  for (final p in ghost.points) {
    if (p.timestampMs <= elapsedMs) {
      out.add(p.position);
    } else {
      break;
    }
  }
  final cur = ghostLatLngAtElapsed(ghost, elapsedMs);
  if (cur != null && (out.isEmpty || out.last != cur)) {
    out.add(cur);
  }
  return out;
}

List<LatLng> ghostTrailAhead(GhostModel ghost, int elapsedMs, int aheadMs) {
  if (ghost.points.isEmpty) {
    return [];
  }
  final end = elapsedMs + aheadMs;
  final out = <LatLng>[];
  var started = false;
  for (final p in ghost.points) {
    if (p.timestampMs < elapsedMs) {
      continue;
    }
    if (p.timestampMs > end) {
      break;
    }
    started = true;
    out.add(p.position);
  }
  if (!started) {
    final cur = ghostLatLngAtElapsed(ghost, elapsedMs);
    if (cur != null) {
      out.add(cur);
    }
  }
  return out;
}
