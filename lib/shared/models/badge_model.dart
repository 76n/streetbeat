import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../core/constants/badges.dart';

class BadgeModel extends Equatable {
  const BadgeModel({
    required this.id,
    required this.earnedAt,
    required this.tier,
  });

  final String id;
  final DateTime earnedAt;
  final BadgeTier tier;

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'earnedAt': Timestamp.fromDate(earnedAt),
      'tier': tier.name,
    };
  }

  static BadgeTier? _parseTier(String? raw) {
    if (raw == null) {
      return null;
    }
    for (final t in BadgeTier.values) {
      if (t.name == raw) {
        return t;
      }
    }
    return null;
  }

  static BadgeModel? tryParse(dynamic raw) {
    if (raw is String) {
      final def = kBadgeById[raw];
      return BadgeModel(
        id: raw,
        earnedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        tier: def?.tier ?? BadgeTier.bronze,
      );
    }
    if (raw is Map) {
      final id = raw['id'] as String? ?? '';
      if (id.isEmpty) {
        return null;
      }
      final def = kBadgeById[id];
      final ts = raw['earnedAt'];
      var at = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
      if (ts is Timestamp) {
        at = ts.toDate();
      }
      final tier =
          _parseTier(raw['tier'] as String?) ?? def?.tier ?? BadgeTier.bronze;
      return BadgeModel(id: id, earnedAt: at, tier: tier);
    }
    return null;
  }

  static List<BadgeModel> parseList(dynamic raw) {
    if (raw is! List<dynamic>) {
      return [];
    }
    final out = <BadgeModel>[];
    for (final e in raw) {
      final m = tryParse(e);
      if (m != null) {
        out.add(m);
      }
    }
    return out;
  }

  @override
  List<Object?> get props => [id, earnedAt, tier];
}
