import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/badges.dart';
import '../../features/run/models/run_model.dart';
import '../models/badge_model.dart';
import '../models/user_model.dart';

class BadgeService {
  BadgeService(this._firestore);

  final FirebaseFirestore _firestore;

  Future<List<BadgeModel>> checkAndAwardBadges(
    String uid,
    RunModel run,
    UserModel user,
  ) async {
    final ref = _firestore.collection('users').doc(uid);
    return _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? {};
      final fresh = UserModel.fromFirestore(
        data,
        runVisitedNewNeighborhood: user.runVisitedNewNeighborhood,
      );
      final existingById = <String, BadgeModel>{};
      for (final b in fresh.badges) {
        existingById.putIfAbsent(b.id, () => b);
      }
      final newly = <BadgeModel>[];
      final now = DateTime.now();
      for (final def in kAllBadgeDefinitions) {
        if (existingById.containsKey(def.id)) {
          continue;
        }
        if (_qualifies(def, fresh, run)) {
          final m = BadgeModel(id: def.id, earnedAt: now, tier: def.tier);
          newly.add(m);
          existingById[def.id] = m;
        }
      }
      if (newly.isEmpty) {
        return <BadgeModel>[];
      }
      final merged = existingById.values.toList()
        ..sort((a, b) {
          final c = a.earnedAt.compareTo(b.earnedAt);
          return c != 0 ? c : a.id.compareTo(b.id);
        });
      tx.update(ref, {
        'badges': merged.map((e) => e.toFirestore()).toList(),
      });
      return newly;
    });
  }

  bool _qualifies(BadgeDefinition def, UserModel u, RunModel r) {
    switch (def.id) {
      case 'first_run':
        return u.totalRuns >= 1;
      case 'three_runs':
        return u.totalRuns >= 3;
      case 'week_streak_1':
        return u.currentStreakWeeks >= 1;
      case 'week_streak_3':
        return u.currentStreakWeeks >= 3;
      case 'week_streak_6':
        return u.currentStreakWeeks >= 6;
      case 'week_streak_10':
        return u.currentStreakWeeks >= 10;
      case 'week_streak_20':
        return u.currentStreakWeeks >= 20;
      case 'early_bird':
        return u.earlyBirdRuns >= 5;
      case 'night_owl':
        return u.nightOwlRuns >= 5;
      case 'rain_warrior':
        return u.rainRuns >= 3;
      case 'explorer_1':
        return u.explorerCoinsLifetime >= 10;
      case 'explorer_2':
        return u.uniqueStreetCells.length >= 20;
      case 'explorer_3':
        return u.uniqueStreetCells.length >= 50;
      case 'new_neighborhood':
        return u.runVisitedNewNeighborhood;
      case 'five_neighborhoods':
        return u.neighborhoodCells.length >= 5;
      case 'elevation_hunter':
        return u.elevationCoinsLifetime >= 20;
      case 'distance_5k':
        return r.distance >= 5000;
      case 'distance_10k':
        return r.distance >= 10000;
      case 'distance_half':
        return r.distance >= 21100;
      case 'first_streetbeat':
        return r.streetbeatCount > 0 &&
            (u.streetbeatSessionsLifetime - r.streetbeatCount) == 0;
      case 'streetbeat_master':
        return u.streetbeatSessionsLifetime >= 10;
      case 'gate_master':
        return u.gatesCapturedLifetime >= 100;
      case 'coin_collector':
        return u.totalCoins >= 1000;
      case 'ghost_beater':
        return u.ghostBeatsLifetime >= 5;
      case 'phantom_hunter':
        return u.phantomGoldLifetime >= 5;
      default:
        return false;
    }
  }
}
