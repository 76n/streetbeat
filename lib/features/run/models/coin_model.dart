import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

enum CoinType {
  standard,
  explorer,
  elevation,
  milestone,
  consistency,
  goal,
  phantomGold,
  personalBest,
}

class CoinModel extends Equatable {
  const CoinModel({
    required this.id,
    required this.position,
    required this.type,
    required this.points,
    required this.spawnedAt,
    this.expiresAt,
    this.isCollected = false,
  });

  final String id;
  final LatLng position;
  final CoinType type;
  final int points;
  final DateTime spawnedAt;
  final DateTime? expiresAt;
  final bool isCollected;

  CoinModel copyWith({
    bool? isCollected,
  }) {
    return CoinModel(
      id: id,
      position: position,
      type: type,
      points: points,
      spawnedAt: spawnedAt,
      expiresAt: expiresAt,
      isCollected: isCollected ?? this.isCollected,
    );
  }

  @override
  List<Object?> get props => [
        id,
        position.latitude,
        position.longitude,
        type,
        points,
        spawnedAt,
        expiresAt,
        isCollected,
      ];

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'position': {'lat': position.latitude, 'lng': position.longitude},
      'type': type.name,
      'points': points,
      'spawnedAt': spawnedAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'isCollected': isCollected,
    };
  }

  static CoinModel? tryFromFirestore(Map<String, dynamic> m) {
    try {
      final pos = m['position'];
      if (pos is! Map) {
        return null;
      }
      final typeName = m['type'] as String? ?? 'standard';
      CoinType type = CoinType.standard;
      for (final t in CoinType.values) {
        if (t.name == typeName) {
          type = t;
          break;
        }
      }
      return CoinModel(
        id: m['id'] as String? ?? '',
        position: LatLng(
          (pos['lat'] as num).toDouble(),
          (pos['lng'] as num).toDouble(),
        ),
        type: type,
        points: (m['points'] as num?)?.toInt() ?? 0,
        spawnedAt: DateTime.tryParse(m['spawnedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        expiresAt: DateTime.tryParse(m['expiresAt'] as String? ?? ''),
        isCollected: m['isCollected'] as bool? ?? false,
      );
    } catch (_) {
      return null;
    }
  }
}

int coinPointsForType(CoinType type) {
  return switch (type) {
    CoinType.standard => 10,
    CoinType.explorer => 25,
    CoinType.elevation => 15,
    CoinType.milestone => 50,
    CoinType.consistency => 20,
    CoinType.goal => 30,
    CoinType.phantomGold => 100,
    CoinType.personalBest => 40,
  };
}
