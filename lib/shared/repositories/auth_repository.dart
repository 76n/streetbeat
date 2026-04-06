import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../features/auth/models/activity_type.dart';
import '../../features/auth/models/race_goal_option.dart';
import '../../features/auth/models/weekly_goal_runs.dart';

class AuthRepository {
  AuthRepository({
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
    required FirebaseFirestore firestore,
  })  : _auth = firebaseAuth,
        _googleSignIn = googleSignIn,
        _firestore = firestore {
    _auth.authStateChanges().listen((user) {
      if (!_forwardController.isClosed) {
        _forwardController.add(user);
      }
    });
  }

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  final StreamController<User?> _forwardController =
      StreamController<User?>.broadcast();

  Stream<User?> get authStateChanges => _forwardController.stream;

  User? get currentUser => _auth.currentUser;

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  Future<void> signInWithGoogle() async {
    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw StateError('Google sign-in was cancelled.');
    }
    final googleAuth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await _auth.signInWithCredential(credential);
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }
    final ref = _firestore.collection('users').doc(user.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set(_defaultUserDocument(
        uid: user.uid,
        name: user.displayName ?? user.email?.split('@').first ?? 'Runner',
        email: user.email ?? '',
        activityType: ActivityType.runner,
        weeklyGoalRuns: WeeklyGoalRuns.three,
        raceGoal: RaceGoalOption.none,
      ));
    }
  }

  Future<void> createUserDocument({
    required String uid,
    required String name,
    required String email,
    required ActivityType activityType,
    required WeeklyGoalRuns weeklyGoalRuns,
    required RaceGoalOption raceGoal,
    String city = '',
  }) {
    return _firestore.collection('users').doc(uid).set(
          _defaultUserDocument(
            uid: uid,
            name: name,
            email: email,
            city: city,
            activityType: activityType,
            weeklyGoalRuns: weeklyGoalRuns,
            raceGoal: raceGoal,
          ),
          SetOptions(merge: true),
        );
  }

  Map<String, Object?> _defaultUserDocument({
    required String uid,
    required String name,
    required String email,
    String city = '',
    required ActivityType activityType,
    required WeeklyGoalRuns weeklyGoalRuns,
    required RaceGoalOption raceGoal,
  }) {
    final race = raceGoal.asFirestoreValue;
    final nameLower = name.trim().toLowerCase();
    return {
      'uid': uid,
      'name': name,
      'nameLower': nameLower,
      'email': email,
      'city': city,
      'activityType': activityType.asFirestoreValue,
      'weeklyGoalRuns': weeklyGoalRuns.count,
      'raceGoal': race,
      'createdAt': FieldValue.serverTimestamp(),
      'totalCoins': 0,
      'totalDistance': 0,
      'totalRuns': 0,
      'currentStreakWeeks': 0,
      'longestStreakWeeks': 0,
      'weeklyRuns': <String>[],
      'friends': <String>[],
      'badges': <Map<String, dynamic>>[],
      'explorerCoinsLifetime': 0,
      'elevationCoinsLifetime': 0,
      'phantomGoldLifetime': 0,
      'gatesCapturedLifetime': 0,
      'streetbeatSessionsLifetime': 0,
      'ghostBeatsLifetime': 0,
      'earlyBirdRuns': 0,
      'nightOwlRuns': 0,
      'rainRuns': 0,
      'neighborhoodCells': <String>[],
      'uniqueStreetCells': <String>[],
      'weeklyCoins': 0,
      'weeklyCoinsWeekToken': '',
      'weeklyDistanceMeters': 0,
      'longestRunMeters': 0,
      'mostCoinsSingleRun': 0,
    };
  }
}
