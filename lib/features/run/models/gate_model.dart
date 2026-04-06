import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

enum GateType {
  standard,
  speed,
  timed,
}

class GateModel extends Equatable {
  const GateModel({
    required this.id,
    required this.position,
    required this.direction,
    required this.type,
    required this.points,
    required this.spawnedAt,
    this.isCapture = false,
    this.isMissed = false,
  });

  final String id;
  final LatLng position;
  final double direction;
  final GateType type;
  final int points;
  final DateTime spawnedAt;
  final bool isCapture;
  final bool isMissed;

  GateModel copyWith({
    bool? isCapture,
    bool? isMissed,
  }) {
    return GateModel(
      id: id,
      position: position,
      direction: direction,
      type: type,
      points: points,
      spawnedAt: spawnedAt,
      isCapture: isCapture ?? this.isCapture,
      isMissed: isMissed ?? this.isMissed,
    );
  }

  @override
  List<Object?> get props => [
        id,
        position.latitude,
        position.longitude,
        direction,
        type,
        points,
        spawnedAt,
        isCapture,
        isMissed,
      ];

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'position': {'lat': position.latitude, 'lng': position.longitude},
      'direction': direction,
      'type': type.name,
      'points': points,
      'spawnedAt': spawnedAt.toIso8601String(),
      'isCapture': isCapture,
      'isMissed': isMissed,
    };
  }

  static GateModel? tryFromFirestore(Map<String, dynamic> m) {
    try {
      final pos = m['position'];
      if (pos is! Map) {
        return null;
      }
      final typeName = m['type'] as String? ?? 'standard';
      GateType type = GateType.standard;
      for (final t in GateType.values) {
        if (t.name == typeName) {
          type = t;
          break;
        }
      }
      return GateModel(
        id: m['id'] as String? ?? '',
        position: LatLng(
          (pos['lat'] as num).toDouble(),
          (pos['lng'] as num).toDouble(),
        ),
        direction: (m['direction'] as num?)?.toDouble() ?? 0,
        type: type,
        points: (m['points'] as num?)?.toInt() ?? 0,
        spawnedAt: DateTime.tryParse(m['spawnedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        isCapture: m['isCapture'] as bool? ?? false,
        isMissed: m['isMissed'] as bool? ?? false,
      );
    } catch (_) {
      return null;
    }
  }
}

int gatePointsForType(GateType type) {
  return switch (type) {
    GateType.standard => 50,
    GateType.speed => 75,
    GateType.timed => 60,
  };
}
