import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

class GhostPoint extends Equatable {
  const GhostPoint({
    required this.position,
    required this.timestampMs,
    required this.distanceFromStart,
  });

  final LatLng position;
  final int timestampMs;
  final double distanceFromStart;

  Map<String, dynamic> toMap() {
    return {
      'lat': position.latitude,
      'lng': position.longitude,
      't': timestampMs,
      'd': distanceFromStart,
    };
  }

  static GhostPoint fromMap(Map<String, dynamic> m) {
    return GhostPoint(
      position: LatLng(
        (m['lat'] as num).toDouble(),
        (m['lng'] as num).toDouble(),
      ),
      timestampMs: (m['t'] as num).toInt(),
      distanceFromStart: (m['d'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [
        position.latitude,
        position.longitude,
        timestampMs,
        distanceFromStart,
      ];
}

class GhostModel extends Equatable {
  const GhostModel({
    required this.runId,
    required this.points,
  });

  final String runId;
  final List<GhostPoint> points;

  @override
  List<Object?> get props => [runId, points];

  Map<String, dynamic> toFirestore() {
    return {
      'runId': runId,
      'points': points.map((e) => e.toMap()).toList(),
    };
  }

  static GhostModel fromFirestore(Map<String, dynamic> m) {
    final raw = m['points'];
    final pts = <GhostPoint>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map<String, dynamic>) {
          pts.add(GhostPoint.fromMap(e));
        }
      }
    }
    return GhostModel(
      runId: m['runId'] as String? ?? '',
      points: pts,
    );
  }
}

double ghostDistanceAtElapsed(GhostModel ghost, int elapsedMs) {
  if (ghost.points.isEmpty) {
    return 0;
  }
  if (elapsedMs <= ghost.points.first.timestampMs) {
    return ghost.points.first.distanceFromStart;
  }
  if (elapsedMs >= ghost.points.last.timestampMs) {
    return ghost.points.last.distanceFromStart;
  }
  for (var i = 0; i < ghost.points.length - 1; i++) {
    final a = ghost.points[i];
    final b = ghost.points[i + 1];
    if (elapsedMs >= a.timestampMs && elapsedMs <= b.timestampMs) {
      final span = b.timestampMs - a.timestampMs;
      if (span <= 0) {
        return b.distanceFromStart;
      }
      final t = (elapsedMs - a.timestampMs) / span;
      return a.distanceFromStart +
          t * (b.distanceFromStart - a.distanceFromStart);
    }
  }
  return ghost.points.last.distanceFromStart;
}
