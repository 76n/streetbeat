import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../features/run/models/run_model.dart';

class FriendRequestDoc {
  FriendRequestDoc({
    required this.id,
    required this.fromUid,
    required this.toUid,
    required this.createdAt,
  });

  final String id;
  final String fromUid;
  final String toUid;
  final DateTime? createdAt;
}

class UserSearchHit {
  UserSearchHit({
    required this.uid,
    required this.name,
    required this.email,
    required this.city,
  });

  final String uid;
  final String name;
  final String email;
  final String city;
}

class LeaderboardRow {
  LeaderboardRow({
    required this.uid,
    required this.name,
    required this.score,
    required this.rank,
  });

  final String uid;
  final String name;
  final int score;
  final int rank;
}

class SocialRepository {
  SocialRepository(
    this._firestore, {
    FirebaseFunctions? functions,
  }) : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  static String friendRequestId(String fromUid, String toUid) =>
      '${fromUid}_$toUid';

  void Function() watchActivityFeed({
    required String myUid,
    required void Function(List<RunModel> runs) onRuns,
  }) {
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? userSub;
    final chunkSubs =
        <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];

    void cancelChunks() {
      for (final s in chunkSubs) {
        s.cancel();
      }
      chunkSubs.clear();
    }

    void subscribeChunks(List<String> uids) {
      cancelChunks();
      if (uids.isEmpty) {
        onRuns([]);
        return;
      }
      final byChunk = <int, Map<String, RunModel>>{};

      void mergeAndEmit() {
        final all = <RunModel>[];
        for (final m in byChunk.values) {
          all.addAll(m.values);
        }
        all.sort((a, b) => b.startedAt.compareTo(a.startedAt));
        onRuns(all.take(20).toList());
      }

      for (var i = 0; i < uids.length; i += 10) {
        final end = i + 10 > uids.length ? uids.length : i + 10;
        final chunk = uids.sublist(i, end);
        final chunkIndex = chunkSubs.length;
        byChunk[chunkIndex] = {};
        final sub = _firestore
            .collection('runs')
            .where('uid', whereIn: chunk)
            .orderBy('startedAt', descending: true)
            .limit(20)
            .snapshots()
            .listen((snap) {
          byChunk[chunkIndex] = {
            for (final d in snap.docs)
              d.id: RunModel.fromFirestore(d.id, d.data()),
          };
          mergeAndEmit();
        });
        chunkSubs.add(sub);
      }
      mergeAndEmit();
    }

    userSub = _firestore.collection('users').doc(myUid).snapshots().listen(
      (snap) {
        final friends = List<String>.from(snap.data()?['friends'] ?? []);
        final uids = {...friends, myUid}.toList();
        subscribeChunks(uids);
      },
    );

    return () {
      userSub?.cancel();
      cancelChunks();
    };
  }

  Stream<List<FriendRequestDoc>> incomingRequestsStream(String myUid) {
    return _firestore
        .collection('friendRequests')
        .where('toUid', isEqualTo: myUid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) {
      return snap.docs.map((d) {
        final m = d.data();
        final ts = m['createdAt'];
        DateTime? at;
        if (ts is Timestamp) {
          at = ts.toDate();
        }
        return FriendRequestDoc(
          id: d.id,
          fromUid: m['fromUid'] as String? ?? '',
          toUid: m['toUid'] as String? ?? '',
          createdAt: at,
        );
      }).toList();
    });
  }

  Future<void> sendFriendRequest({required String toUid}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('Not signed in.');
    }
    if (uid == toUid) {
      return;
    }
    try {
      final callable = _functions.httpsCallable('sendFriendRequest');
      await callable.call<Map<String, dynamic>>({'toUid': toUid});
    } on FirebaseFunctionsException catch (e) {
      throw StateError(e.message ?? e.code);
    }
  }

  Future<void> acceptFriendRequest({
    required String requesterUid,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('Not signed in.');
    }
    try {
      final callable = _functions.httpsCallable('acceptFriendRequest');
      await callable.call<Map<String, dynamic>>({'requesterUid': requesterUid});
    } on FirebaseFunctionsException catch (e) {
      throw StateError(e.message ?? e.code);
    }
  }

  Future<void> declineFriendRequest({
    required String requesterUid,
  }) async {
    final accepterUid = FirebaseAuth.instance.currentUser?.uid;
    if (accepterUid == null) {
      return;
    }
    final id = friendRequestId(requesterUid, accepterUid);
    await _firestore.collection('friendRequests').doc(id).delete();
  }

  Future<List<UserSearchHit>> searchUsers({
    required String myUid,
    required String query,
  }) async {
    final q = query.trim();
    if (q.length < 2) {
      return [];
    }
    if (q.contains('@')) {
      final email = q.toLowerCase();
      final snap = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(10)
          .get();
      return snap.docs
          .where((d) => d.id != myUid)
          .map(
            (d) => UserSearchHit(
              uid: d.id,
              name: d.data()['name'] as String? ?? '',
              email: d.data()['email'] as String? ?? '',
              city: d.data()['city'] as String? ?? '',
            ),
          )
          .toList();
    }
    final qLow = q.toLowerCase();
    final snap = await _firestore
        .collection('users')
        .orderBy('nameLower')
        .startAt([qLow])
        .endAt(['$qLow\uf8ff'])
        .limit(25)
        .get();
    return snap.docs
        .where((d) => d.id != myUid)
        .map(
          (d) => UserSearchHit(
            uid: d.id,
            name: d.data()['name'] as String? ?? '',
            email: d.data()['email'] as String? ?? '',
            city: d.data()['city'] as String? ?? '',
          ),
        )
        .toList();
  }

  Future<void> toggleKudos({
    required String runId,
    required String uid,
  }) async {
    final ref = _firestore.collection('runs').doc(runId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) {
        return;
      }
      final list = List<String>.from(snap.data()?['kudosUserIds'] ?? []);
      if (list.contains(uid)) {
        list.remove(uid);
      } else {
        list.add(uid);
      }
      tx.update(ref, {
        'kudosUserIds': list,
        'kudosCount': list.length,
      });
    });
  }

  Future<List<LeaderboardRow>> leaderboardForUids({
    required List<String> uids,
    required int Function(Map<String, dynamic> data) scoreFor,
  }) async {
    if (uids.isEmpty) {
      return [];
    }
    final snaps = await Future.wait(
      uids.map((id) => _firestore.collection('users').doc(id).get()),
    );
    final tmp = <({String uid, String name, int score})>[];
    for (final s in snaps) {
      if (!s.exists) {
        continue;
      }
      final m = s.data()!;
      tmp.add((
        uid: s.id,
        name: m['name'] as String? ?? 'Runner',
        score: scoreFor(m),
      ));
    }
    tmp.sort((a, b) => b.score.compareTo(a.score));
    return List.generate(
      tmp.length,
      (i) => LeaderboardRow(
        uid: tmp[i].uid,
        name: tmp[i].name,
        score: tmp[i].score,
        rank: i + 1,
      ),
    );
  }
}
