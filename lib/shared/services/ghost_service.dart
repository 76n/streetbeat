import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/run/models/ghost_model.dart';

class GhostService {
  GhostService(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _segmentRef(
      String uid, String segmentKey) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('ghost_segments')
        .doc(segmentKey);
  }

  Future<GhostModel?> loadBestGhost({
    required String uid,
    required String segmentKey,
  }) async {
    final snap = await _segmentRef(uid, segmentKey).get();
    if (!snap.exists || snap.data() == null) {
      return null;
    }
    return GhostModel.fromFirestore(snap.data()!);
  }

  Future<bool> saveGhostIfBetter({
    required String uid,
    required String segmentKey,
    required GhostModel ghost,
    required int durationSeconds,
    required double distanceMeters,
  }) async {
    final ref = _segmentRef(uid, segmentKey);
    var wrote = false;
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final prevDur = snap.data()?['bestDurationSeconds'] as int?;
      final prevDist = (snap.data()?['bestDistance'] as num?)?.toDouble();
      var shouldWrite = !snap.exists;
      if (!shouldWrite && prevDur != null) {
        if (durationSeconds < prevDur) {
          shouldWrite = true;
        } else if (durationSeconds == prevDur &&
            prevDist != null &&
            distanceMeters > prevDist) {
          shouldWrite = true;
        }
      }
      if (!shouldWrite) {
        return;
      }
      wrote = true;
      tx.set(
          ref,
          {
            ...ghost.toFirestore(),
            'bestDurationSeconds': durationSeconds,
            'bestDistance': distanceMeters,
            'segmentKey': segmentKey,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));
    });
    return wrote;
  }
}
