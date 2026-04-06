import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/badge_geo_utils.dart';
import '../../../core/utils/location_utils.dart';
import '../../../core/utils/week_utils.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/services/badge_service.dart';
import '../../../shared/services/ghost_service.dart';
import '../../../shared/services/local_notification_service.dart';
import '../../../shared/services/osm_service.dart';
import '../models/active_objective.dart';
import '../models/coin_model.dart';
import '../models/gate_model.dart';
import '../models/ghost_model.dart';
import '../models/run_model.dart';
import '../models/run_summary_payload.dart';
import '../utils/pace_chart_utils.dart';
import 'run_engine_helpers.dart';
import 'run_event.dart' as re;
import 'run_state.dart';

class RunBloc extends Bloc<re.RunEvent, RunState> {
  RunBloc({
    required OsmService osmService,
    required GhostService ghostService,
    required BadgeService badgeService,
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required LocalNotificationService localNotifications,
    Uuid? uuid,
  })  : _osm = osmService,
        _ghostService = ghostService,
        _badgeService = badgeService,
        _firestore = firestore,
        _auth = auth,
        _localNotifications = localNotifications,
        _uuid = uuid ?? const Uuid(),
        super(const RunIdle()) {
    on<re.RunStarted>(_onRunStarted);
    on<re.RunPaused>(_onRunPaused);
    on<re.RunResumed>(_onRunResumed);
    on<re.RunStopped>(_onRunStopped);
    on<re.LocationUpdated>(_onLocationUpdated);
    on<re.CoinCollected>(_onCoinCollected);
    on<re.GateCapture>(_onGateCapture);
    on<re.GateMissed>(_onGateMissed);
    on<re.GhostLoaded>(_onGhostLoaded);
    on<re.RunCelebrationAcknowledged>(_onCelebrationAcknowledged);
  }

  final OsmService _osm;
  final GhostService _ghostService;
  final BadgeService _badgeService;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final LocalNotificationService _localNotifications;
  final Uuid _uuid;
  final math.Random _rng = math.Random();

  static const _tiers = [1.0, 1.5, 2.0, 3.0, 5.0, 10.0];
  static const _graceStopped = Duration(seconds: 25);
  static const _decayStep = Duration(seconds: 5);
  static const _streetbeatDuration = Duration(seconds: 30);
  static const _phantomInterval = Duration(seconds: 45);
  static const _pathRefreshMoveM = 80.0;

  DateTime? _startedAt;
  DateTime? _pauseBegan;
  int _pausedMs = 0;

  RunModel? _run;
  List<CoinModel> _coins = [];
  List<GateModel> _gates = [];
  List<LatLng> _route = [];
  double _distance = 0;
  int _streetbeatCount = 0;
  int _totalScore = 0;
  double _maxMultiplierSeen = 1;
  double? _bestSecPerKm;

  int _tierIndex = 0;
  double _tierProgress = 0;
  bool _streetbeatActive = false;
  DateTime? _streetbeatEndsAt;

  DateTime? _stopStartedAt;
  DateTime? _lastDecayAt;

  DateTime? _paceGoodSince;
  bool _pace30Awarded = false;
  bool _pace60Awarded = false;

  GhostModel? _ghost;
  String _segmentKey = 'default';
  List<List<LatLng>> _segments = [];
  DateTime? _pathsFetchedAt;
  LatLng? _pathsCenter;

  double _ghostDeltaSeconds = 0;
  bool? _playerAheadGhost;

  ActiveObjective _objective = _initialObjective(0);
  int _objectiveOrdinal = 0;

  final Map<String, double> _gateMinDist = {};
  final Map<String, bool> _gateFlagWrongBearing = {};

  DateTime? _lastPhantomRollAt;
  int _lastMilestoneKm = 0;

  RunCelebrationKind? _pendingCelebration;

  bool get _isPaused => state is RunPaused;

  static ActiveObjective _initialObjective(int ordinal) {
    return switch (ordinal % 4) {
      0 => const ActiveObjective(
          kind: ObjectiveKind.hitGates,
          target: 5,
          progress: 0,
        ),
      1 => const ActiveObjective(
          kind: ObjectiveKind.collectCoins,
          target: 20,
          progress: 0,
        ),
      2 => const ActiveObjective(
          kind: ObjectiveKind.maintainPace,
          target: 60,
          progress: 0,
        ),
      _ => const ActiveObjective(
          kind: ObjectiveKind.reachKm,
          target: 1000,
          progress: 0,
        ),
    };
  }

  ActiveObjective _rollNextObjective() {
    _objectiveOrdinal++;
    final base = _initialObjective(_objectiveOrdinal);
    if (base.kind == ObjectiveKind.reachKm) {
      final nextKmMeters = ((_distance / 1000).floor() + 1) * 1000;
      return ActiveObjective(
        kind: ObjectiveKind.reachKm,
        target: nextKmMeters,
        progress: _distance.round().clamp(0, nextKmMeters),
      );
    }
    return base;
  }

  double get _multiplier {
    final i = _tierIndex.clamp(0, _tiers.length - 1);
    return _tiers[i];
  }

  int _elapsedMs(DateTime now) {
    if (_startedAt == null) {
      return 0;
    }
    var ms = now.difference(_startedAt!).inMilliseconds - _pausedMs;
    if (_pauseBegan != null) {
      ms -= now.difference(_pauseBegan!).inMilliseconds;
    }
    return ms.clamp(0, 1 << 30);
  }

  void _startStreetbeat(DateTime now) {
    _tierIndex = 5;
    _tierProgress = 0;
    _streetbeatActive = true;
    _streetbeatEndsAt = now.add(_streetbeatDuration);
    _streetbeatCount++;
  }

  void _resolveStreetbeatExpiry(DateTime now) {
    if (_streetbeatActive &&
        _streetbeatEndsAt != null &&
        !now.isBefore(_streetbeatEndsAt!)) {
      _streetbeatActive = false;
      _streetbeatEndsAt = null;
      _tierIndex = 4;
      _tierProgress = 0;
    }
  }

  void _addTierProgress(double amount, DateTime now) {
    if (_tierIndex >= 5) {
      return;
    }
    var x = _tierProgress + amount;
    while (x >= 1 && _tierIndex < 5) {
      x -= 1;
      _tierIndex++;
      if (_tierIndex == 5) {
        _startStreetbeat(now);
        x = 0;
        break;
      }
    }
    _tierProgress = x.clamp(0, 0.999);
  }

  void _dropOneTier() {
    final m = _multiplier;
    final newM = dropOneMultiplierTier(m);
    final idx = _tiers.indexWhere((t) => (t - newM).abs() < 0.05);
    _tierIndex = idx >= 0 ? idx : 0;
    _tierProgress = 0;
    if (_streetbeatActive) {
      _streetbeatActive = false;
      _streetbeatEndsAt = null;
      if (_tierIndex >= 5) {
        _tierIndex = 4;
      }
    }
  }

  void _updateStopMultiplierDecay(DateTime now, double speed) {
    if (speed > 0.5) {
      _stopStartedAt = null;
      _lastDecayAt = null;
      return;
    }
    _stopStartedAt ??= now;
    final stoppedFor = now.difference(_stopStartedAt!);
    if (stoppedFor < _graceStopped) {
      _lastDecayAt = null;
      return;
    }
    final decayStart = _stopStartedAt!.add(_graceStopped);
    var cursor = _lastDecayAt ?? decayStart;
    while (now.difference(cursor) >= _decayStep) {
      _dropOneTier();
      cursor = cursor.add(_decayStep);
    }
    _lastDecayAt = cursor;
  }

  void _updatePaceBonuses(DateTime now, double speed) {
    if (speed < 1.2) {
      _paceGoodSince = null;
      _pace30Awarded = false;
      _pace60Awarded = false;
      return;
    }
    _paceGoodSince ??= now;
    final held = now.difference(_paceGoodSince!);
    if (!_pace30Awarded && held >= const Duration(seconds: 30)) {
      _pace30Awarded = true;
      _addTierProgress(0.3, now);
    }
    if (!_pace60Awarded && held >= const Duration(seconds: 60)) {
      _pace60Awarded = true;
      _addTierProgress(0.5, now);
    }
  }

  int _coinsAhead(LatLng pos, double bearing) {
    return _coins.where((c) {
      if (c.isCollected) {
        return false;
      }
      final d = LocationUtils.distanceMeters(pos, c.position);
      if (d > 160) {
        return false;
      }
      return LocationUtils.isPointAhead(pos, bearing, c.position, 85);
    }).length;
  }

  int _gatesAhead(LatLng pos, double bearing) {
    return _gates.where((g) {
      if (g.isCapture || g.isMissed) {
        return false;
      }
      final d = LocationUtils.distanceMeters(pos, g.position);
      if (d > 180) {
        return false;
      }
      return LocationUtils.isPointAhead(pos, bearing, g.position, 85);
    }).length;
  }

  Future<void> _refreshPathsIfNeeded(LatLng pos) async {
    final now = DateTime.now();
    final needTime = _pathsFetchedAt == null ||
        now.difference(_pathsFetchedAt!) > const Duration(seconds: 45);
    final needMove = _pathsCenter == null ||
        LocationUtils.distanceMeters(_pathsCenter!, pos) > _pathRefreshMoveM;
    if (!needTime && !needMove) {
      return;
    }
    _segments = await _osm.fetchNearbyPaths(pos, 280);
    _pathsFetchedAt = now;
    _pathsCenter = pos;
    _segmentKey = segmentKeyForPaths(_segments);
  }

  Future<void> _ensureCoins(
      Emitter<RunState> emit, LatLng pos, double bearing) async {
    var attempts = 0;
    while (_coinsAhead(pos, bearing) < 3 && attempts < 8) {
      attempts++;
      if (_coins.length >= 24) {
        break;
      }
      final spawn = await _osm.findValidSpawnPoint(pos, bearing, 38, 125);
      if (spawn == null) {
        break;
      }
      final t = rollCoinType(_rng);
      final c = CoinModel(
        id: _uuid.v4(),
        position: spawn,
        type: t,
        points: coinPointsForType(t),
        spawnedAt: DateTime.now(),
      );
      _coins = [..._coins, c];
      if (_coinsAhead(pos, bearing) >= 5) {
        break;
      }
    }
    if (!emit.isDone) {
      _emitActive(emit);
    }
  }

  Future<void> _ensureGates(Emitter<RunState> emit, LatLng pos) async {
    var attempts = 0;
    while (_gatesAhead(pos, _lastBearing) < 1 && attempts < 6) {
      attempts++;
      if (_gates.length >= 8) {
        break;
      }
      final spawn = await _osm.findValidSpawnPoint(pos, _lastBearing, 45, 140);
      if (spawn == null) {
        break;
      }
      final dir = bearingAlongNearestPath(spawn, _segments, _rng);
      final gt = switch (_rng.nextInt(10)) {
        < 5 => GateType.standard,
        < 8 => GateType.speed,
        _ => GateType.timed,
      };
      final g = GateModel(
        id: _uuid.v4(),
        position: spawn,
        direction: dir,
        type: gt,
        points: gatePointsForType(gt),
        spawnedAt: DateTime.now(),
      );
      _gates = [..._gates, g];
      if (_gatesAhead(pos, _lastBearing) >= 2) {
        break;
      }
    }
    attempts = 0;
    while (_gatesAhead(pos, _lastBearing) < 2 && attempts < 6) {
      attempts++;
      if (_gates.length >= 8) {
        break;
      }
      final spawn = await _osm.findValidSpawnPoint(pos, _lastBearing, 50, 155);
      if (spawn == null) {
        break;
      }
      final dir = bearingAlongNearestPath(spawn, _segments, _rng);
      final gt = switch (_rng.nextInt(10)) {
        < 5 => GateType.standard,
        < 8 => GateType.speed,
        _ => GateType.timed,
      };
      final g = GateModel(
        id: _uuid.v4(),
        position: spawn,
        direction: dir,
        type: gt,
        points: gatePointsForType(gt),
        spawnedAt: DateTime.now(),
      );
      _gates = [..._gates, g];
      if (_gatesAhead(pos, _lastBearing) >= 2) {
        break;
      }
    }
    if (!emit.isDone) {
      _emitActive(emit);
    }
  }

  double _lastBearing = 0;

  Future<void> _maybePhantomGold(
    Emitter<RunState> emit,
    LatLng pos,
    double bearing,
  ) async {
    final now = DateTime.now();
    if (_lastPhantomRollAt == null) {
      _lastPhantomRollAt = now;
      return;
    }
    if (now.difference(_lastPhantomRollAt!) < _phantomInterval) {
      return;
    }
    _lastPhantomRollAt = now;
    if (_rng.nextDouble() > 0.05) {
      return;
    }
    final spawn = await _osm.findValidSpawnPoint(pos, bearing, 40, 120);
    if (spawn == null || emit.isDone) {
      return;
    }
    final expires = now.add(const Duration(seconds: 45));
    _coins = [
      ..._coins,
      CoinModel(
        id: _uuid.v4(),
        position: spawn,
        type: CoinType.phantomGold,
        points: coinPointsForType(CoinType.phantomGold),
        spawnedAt: now,
        expiresAt: expires,
      ),
    ];
    unawaited(_localNotifications.showPhantomGoldCoin());
    _emitActive(emit);
  }

  Future<void> _maybeMilestoneKm(
    Emitter<RunState> emit,
    LatLng pos,
    double bearing,
  ) async {
    final km = (_distance / 1000).floor();
    if (km <= _lastMilestoneKm) {
      return;
    }
    _lastMilestoneKm = km;
    final spawn = await _osm.findValidSpawnPoint(pos, bearing, 48, 120);
    if (spawn == null || emit.isDone) {
      return;
    }
    _coins = [
      ..._coins,
      CoinModel(
        id: _uuid.v4(),
        position: spawn,
        type: CoinType.milestone,
        points: coinPointsForType(CoinType.milestone),
        spawnedAt: DateTime.now(),
      ),
    ];
  }

  Future<void> _maybePersonalBestCoin(
    Emitter<RunState> emit,
    LatLng pos,
    double bearing,
  ) async {
    if (_ghost == null || _ghostDeltaSeconds <= 3) {
      return;
    }
    final hasPb =
        _coins.any((c) => !c.isCollected && c.type == CoinType.personalBest);
    if (hasPb || _rng.nextDouble() > 0.2) {
      return;
    }
    final spawn = await _osm.findValidSpawnPoint(pos, bearing, 42, 115);
    if (spawn == null || emit.isDone) {
      return;
    }
    _coins = [
      ..._coins,
      CoinModel(
        id: _uuid.v4(),
        position: spawn,
        type: CoinType.personalBest,
        points: coinPointsForType(CoinType.personalBest),
        spawnedAt: DateTime.now(),
      ),
    ];
    _emitActive(emit);
  }

  bool _gateCaptureOk(
      GateModel g, LatLng p, double playerBearing, double speed) {
    if (LocationUtils.distanceMeters(g.position, p) > 5) {
      return false;
    }
    if (speed < 1.0) {
      return false;
    }
    return LocationUtils.angleDiffDeg(playerBearing, g.direction).abs() <= 30;
  }

  void _emitActive(Emitter<RunState> emit) {
    if (_run == null) {
      return;
    }
    final m = _multiplier;
    if (m > _maxMultiplierSeen) {
      _maxMultiplierSeen = m;
    }
    final run = _run!.copyWith(
      distance: _distance,
      route: _route,
      coins: List<CoinModel>.from(_coins),
      gates: List<GateModel>.from(_gates),
      totalScore: _totalScore,
      maxMultiplier: _maxMultiplierSeen,
      streetbeatCount: _streetbeatCount,
      ghostDelta: _ghostDeltaSeconds,
    );
    emit(
      RunActive(
        RunSessionData(
          run: run,
          coins: List<CoinModel>.from(_coins),
          gates: List<GateModel>.from(_gates),
          multiplier: m,
          ghostDeltaSeconds: _ghostDeltaSeconds,
          streetbeatActive: _streetbeatActive,
          streetbeatEndsAt: _streetbeatEndsAt,
          activeObjective: _objective,
          ghost: _ghost,
        ),
        celebration: _pendingCelebration,
      ),
    );
    _pendingCelebration = null;
  }

  void _completeObjectiveIfNeeded(DateTime now) {
    if (!_objective.isComplete) {
      return;
    }
    _pendingCelebration = RunCelebrationKind.objectiveComplete;
    _addTierProgress(0.15, now);
    _objective = _rollNextObjective();
    if (_objective.kind == ObjectiveKind.maintainPace) {
      _paceGoodSince = null;
      _pace30Awarded = false;
      _pace60Awarded = false;
    }
  }

  void _bumpObjectiveOnCoin() {
    if (_objective.kind != ObjectiveKind.collectCoins) {
      return;
    }
    _objective = _objective.copyWith(progress: _objective.progress + 1);
  }

  void _bumpObjectiveOnGate() {
    if (_objective.kind != ObjectiveKind.hitGates) {
      return;
    }
    _objective = _objective.copyWith(progress: _objective.progress + 1);
  }

  void _updateObjectivePace(double speed) {
    if (_objective.kind != ObjectiveKind.maintainPace) {
      return;
    }
    if (speed >= 1.2) {
      _objective = _objective.copyWith(progress: _objective.progress + 1);
    } else {
      _objective = _objective.copyWith(progress: 0);
    }
  }

  void _updateObjectiveKm() {
    if (_objective.kind != ObjectiveKind.reachKm) {
      return;
    }
    final t = _objective.target;
    _objective = _objective.copyWith(
      progress: _distance.round().clamp(0, t),
    );
  }

  Future<void> _onRunStarted(
      re.RunStarted event, Emitter<RunState> emit) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      emit(const RunFailure('Not signed in'));
      return;
    }
    _resetSession();
    _startedAt = DateTime.now();
    _pauseBegan = null;
    _pausedMs = 0;
    _lastBearing = event.bearing;
    _pace30Awarded = false;
    _pace60Awarded = false;
    final id = _uuid.v4();
    _run = RunModel(
      id: id,
      uid: uid,
      startedAt: _startedAt!,
    );
    _route = [event.position];
    _distance = 0;

    await _refreshPathsIfNeeded(event.position);
    if (emit.isDone) {
      return;
    }

    _segmentKey = segmentKeyForPaths(_segments);
    final ghost = await _ghostService.loadBestGhost(
      uid: uid,
      segmentKey: _segmentKey,
    );
    if (emit.isDone) {
      return;
    }
    _ghost = ghost;

    _objective = _initialObjective(_objectiveOrdinal);
    _emitActive(emit);

    await _ensureCoins(emit, event.position, event.bearing);
    if (emit.isDone) {
      return;
    }
    await _ensureGates(emit, event.position);
  }

  void _resetSession() {
    _run = null;
    _coins = [];
    _gates = [];
    _route = [];
    _distance = 0;
    _streetbeatCount = 0;
    _totalScore = 0;
    _maxMultiplierSeen = 1;
    _bestSecPerKm = null;
    _tierIndex = 0;
    _tierProgress = 0;
    _streetbeatActive = false;
    _streetbeatEndsAt = null;
    _stopStartedAt = null;
    _lastDecayAt = null;
    _paceGoodSince = null;
    _pace30Awarded = false;
    _pace60Awarded = false;
    _ghost = null;
    _segmentKey = 'default';
    _segments = [];
    _pathsFetchedAt = null;
    _pathsCenter = null;
    _ghostDeltaSeconds = 0;
    _playerAheadGhost = null;
    _objectiveOrdinal = 0;
    _objective = _initialObjective(0);
    _gateMinDist.clear();
    _gateFlagWrongBearing.clear();
    _lastPhantomRollAt = null;
    _lastMilestoneKm = 0;
    _pendingCelebration = null;
  }

  void _onRunPaused(re.RunPaused event, Emitter<RunState> emit) {
    final s = state;
    if (s is! RunActive) {
      return;
    }
    _pauseBegan = DateTime.now();
    emit(RunPaused(s.data));
  }

  void _onRunResumed(re.RunResumed event, Emitter<RunState> emit) {
    final s = state;
    if (s is! RunPaused || _pauseBegan == null) {
      return;
    }
    _pausedMs += DateTime.now().difference(_pauseBegan!).inMilliseconds;
    _pauseBegan = null;
    emit(RunActive(s.data));
  }

  Future<void> _onLocationUpdated(
    re.LocationUpdated event,
    Emitter<RunState> emit,
  ) async {
    if (_isPaused || _run == null) {
      return;
    }
    if (state is! RunActive) {
      return;
    }

    final now = DateTime.now();
    _lastBearing = event.bearing;
    _distance = event.distanceTraveled;
    _route = List<LatLng>.from(event.routeCompressed);

    if (event.speed > 0.5) {
      final spk = 1000.0 / event.speed;
      if (spk.isFinite &&
          spk > 0 &&
          (_bestSecPerKm == null || spk < _bestSecPerKm!)) {
        _bestSecPerKm = spk;
      }
    }

    final elapsed = _elapsedMs(now);
    _resolveStreetbeatExpiry(now);
    _updateStopMultiplierDecay(now, event.speed);
    _updatePaceBonuses(now, event.speed);

    _coins = _coins.where((c) {
      if (c.expiresAt == null) {
        return true;
      }
      return !c.isCollected && now.isBefore(c.expiresAt!);
    }).toList();

    _ghostDeltaSeconds = ghostDeltaSeconds(
      ghost: _ghost,
      elapsedMs: elapsed,
      playerDistance: _distance,
      playerSpeed: event.speed,
    );

    final ahead = playerAheadOfGhost(_ghost, elapsed, _distance);
    final ghostAhead = ghostAheadOfPlayer(_ghost, elapsed, _distance);
    if (_playerAheadGhost != null) {
      if (!_playerAheadGhost! && ahead) {
        _pendingCelebration = RunCelebrationKind.playerPassedGhost;
      } else if (_playerAheadGhost! && ghostAhead) {
        _pendingCelebration = RunCelebrationKind.ghostPassedPlayer;
      }
    }
    _playerAheadGhost = ahead;

    for (final c in List<CoinModel>.from(_coins)) {
      if (c.isCollected) {
        continue;
      }
      if (LocationUtils.distanceMeters(event.position, c.position) <= 8) {
        await _applyCoinCollect(c.id, emit, now);
        if (emit.isDone) {
          return;
        }
      }
    }

    for (final g in List<GateModel>.from(_gates)) {
      if (g.isCapture || g.isMissed) {
        continue;
      }
      final id = g.id;
      final d = LocationUtils.distanceMeters(event.position, g.position);
      final prevMin = _gateMinDist[id];
      _gateMinDist[id] = prevMin == null ? d : (d < prevMin ? d : prevMin);

      if (d <= 5 && event.speed > 0.8) {
        final diff =
            LocationUtils.angleDiffDeg(event.bearing, g.direction).abs();
        if (diff > 30) {
          _gateFlagWrongBearing[id] = true;
        }
      }

      if (_gateCaptureOk(g, event.position, event.bearing, event.speed)) {
        await _applyGateCapture(id, emit, now);
        if (emit.isDone) {
          return;
        }
        continue;
      }

      if (_gateFlagWrongBearing[id] == true && d > 6) {
        await _applyGateMiss(id, emit);
        if (emit.isDone) {
          return;
        }
        continue;
      }

      if (d > 50 && (_gateMinDist[id] ?? 999) < 30) {
        await _applyGateMiss(id, emit);
        if (emit.isDone) {
          return;
        }
      }
    }

    _updateObjectivePace(event.speed);
    _updateObjectiveKm();
    _completeObjectiveIfNeeded(now);
    if (emit.isDone) {
      return;
    }

    await _maybeMilestoneKm(emit, event.position, event.bearing);
    if (emit.isDone) {
      return;
    }

    await _refreshPathsIfNeeded(event.position);
    if (emit.isDone) {
      return;
    }

    await _maybePhantomGold(emit, event.position, event.bearing);
    if (emit.isDone) {
      return;
    }
    await _maybePersonalBestCoin(emit, event.position, event.bearing);
    if (emit.isDone) {
      return;
    }

    await _ensureCoins(emit, event.position, event.bearing);
    if (emit.isDone) {
      return;
    }
    await _ensureGates(emit, event.position);
    if (emit.isDone) {
      return;
    }

    _emitActive(emit);
  }

  Future<void> _applyCoinCollect(
      String coinId, Emitter<RunState> emit, DateTime now) async {
    final idx = _coins.indexWhere((c) => c.id == coinId);
    if (idx < 0) {
      return;
    }
    final c = _coins[idx];
    if (c.isCollected) {
      return;
    }
    final m = _multiplier;
    _totalScore += (c.points * m).round();
    _coins = [
      ..._coins.sublist(0, idx),
      c.copyWith(isCollected: true),
      ..._coins.sublist(idx + 1),
    ];
    _addTierProgress(0.1, now);
    _bumpObjectiveOnCoin();
    _completeObjectiveIfNeeded(now);
    if (emit.isDone) {
      return;
    }
    _emitActive(emit);
  }

  Future<void> _onCoinCollected(
    re.CoinCollected event,
    Emitter<RunState> emit,
  ) async {
    if (_run == null || _isPaused) {
      return;
    }
    await _applyCoinCollect(event.coinId, emit, DateTime.now());
  }

  Future<void> _applyGateCapture(
      String gateId, Emitter<RunState> emit, DateTime now) async {
    final idx = _gates.indexWhere((g) => g.id == gateId);
    if (idx < 0) {
      return;
    }
    final g = _gates[idx];
    if (g.isCapture || g.isMissed) {
      return;
    }
    final m = _multiplier;
    _totalScore += (g.points * m).round();
    _gates = [
      ..._gates.sublist(0, idx),
      g.copyWith(isCapture: true),
      ..._gates.sublist(idx + 1),
    ];
    _addTierProgress(0.5, now);
    _bumpObjectiveOnGate();
    _gateMinDist.remove(gateId);
    _gateFlagWrongBearing.remove(gateId);
    _completeObjectiveIfNeeded(now);
    if (emit.isDone) {
      return;
    }
    _emitActive(emit);
  }

  Future<void> _applyGateMiss(String gateId, Emitter<RunState> emit) async {
    final idx = _gates.indexWhere((g) => g.id == gateId);
    if (idx < 0) {
      return;
    }
    final g = _gates[idx];
    if (g.isCapture || g.isMissed) {
      return;
    }
    _dropOneTier();
    _gates = [
      ..._gates.sublist(0, idx),
      g.copyWith(isMissed: true),
      ..._gates.sublist(idx + 1),
    ];
    _gateMinDist.remove(gateId);
    _gateFlagWrongBearing.remove(gateId);
    _emitActive(emit);
  }

  Future<void> _onGateCapture(
    re.GateCapture event,
    Emitter<RunState> emit,
  ) async {
    if (_run == null || _isPaused) {
      return;
    }
    await _applyGateCapture(event.gateId, emit, DateTime.now());
  }

  Future<void> _onGateMissed(
    re.GateMissed event,
    Emitter<RunState> emit,
  ) async {
    if (_run == null || _isPaused) {
      return;
    }
    await _applyGateMiss(event.gateId, emit);
  }

  void _onGhostLoaded(re.GhostLoaded event, Emitter<RunState> emit) {
    _ghost = event.ghost;
    if (state is RunActive) {
      _emitActive(emit);
    } else if (state is RunPaused) {
      final p = state as RunPaused;
      final d = p.data;
      emit(
        RunPaused(
          RunSessionData(
            run: d.run,
            coins: d.coins,
            gates: d.gates,
            multiplier: d.multiplier,
            ghostDeltaSeconds: d.ghostDeltaSeconds,
            streetbeatActive: d.streetbeatActive,
            streetbeatEndsAt: d.streetbeatEndsAt,
            activeObjective: d.activeObjective,
            ghost: _ghost,
          ),
        ),
      );
    }
  }

  void _onCelebrationAcknowledged(
    re.RunCelebrationAcknowledged event,
    Emitter<RunState> emit,
  ) {
    final s = state;
    if (s is RunActive) {
      emit(RunActive(s.data));
    }
  }

  Future<void> _onRunStopped(
      re.RunStopped event, Emitter<RunState> emit) async {
    if (_run == null) {
      emit(const RunIdle());
      return;
    }
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      emit(const RunFailure('Not signed in'));
      return;
    }

    final now = DateTime.now();
    if (_pauseBegan != null) {
      _pausedMs += now.difference(_pauseBegan!).inMilliseconds;
      _pauseBegan = null;
    }
    final elapsedSec = (_elapsedMs(now) / 1000).round();
    final avgSpeed = elapsedSec > 0 ? _distance / elapsedSec : 0.0;
    final avgPace = LocationUtils.formatPace(avgSpeed);
    final maxPaceStr = _bestSecPerKm != null
        ? LocationUtils.formatPace(1000.0 / _bestSecPerKm!)
        : null;

    final collectedCoins = _coins.where((c) => c.isCollected).length;
    final weekToken = WeekUtils.isoWeekToken(now.toUtc());

    final userRef = _firestore.collection('users').doc(uid);
    final userSnap = await userRef.get();
    if (emit.isDone) {
      return;
    }

    final data = userSnap.data() ?? {};
    final weeklyGoal = (data['weeklyGoalRuns'] as num?)?.toInt() ?? 3;
    final prevWeekly = (data['weeklyRuns'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];
    final newWeekly = [...prevWeekly, weekToken];
    final streak = WeekUtils.streakWeeksMeetingGoal(
      weeklyRuns: newWeekly,
      weeklyGoalRuns: weeklyGoal,
      now: now.toUtc(),
    );
    final prevLongest = (data['longestStreakWeeks'] as num?)?.toInt() ?? 0;
    final longest = math.max(prevLongest, streak);

    final previousStreakWeeks =
        (data['currentStreakWeeks'] as num?)?.toInt() ?? 0;
    final runsThisWeekAfterRun = newWeekly.where((w) => w == weekToken).length;

    final ghostReplayPath =
        _ghost?.points.map((e) => e.position).toList() ?? <LatLng>[];
    final hadGhost = _ghost != null && _ghost!.points.length >= 2;
    final playerPaceSamples =
        paceSamplesFromRoute(_route, elapsedSec, _distance);
    final ghostPaceSamples =
        _ghost != null ? paceSamplesFromGhost(_ghost!) : <PaceSample>[];

    final rawName = (data['name'] as String?)?.trim();
    final displayName =
        rawName != null && rawName.isNotEmpty ? rawName : 'Runner';

    final completed = _run!.copyWith(
      endedAt: now,
      distance: _distance,
      durationSeconds: elapsedSec,
      averagePace: avgPace,
      maxPace: maxPaceStr,
      coins: List<CoinModel>.from(_coins),
      gates: List<GateModel>.from(_gates),
      route: List<LatLng>.from(_route),
      totalScore: _totalScore,
      maxMultiplier: _maxMultiplierSeen,
      streetbeatCount: _streetbeatCount,
      ghostDelta: _ghostDeltaSeconds,
      weekToken: weekToken,
      runnerName: displayName,
      runnerCity: data['city'] as String? ?? '',
      segmentKey: _segmentKey,
    );

    final prevNeighborhoods = (data['neighborhoodCells'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toSet() ??
        <String>{};
    final neighborhoodKeys =
        neighborhoodKeysFromRoute(completed.route).toList();
    final runVisitedNewNeighborhood =
        neighborhoodKeys.any((k) => !prevNeighborhoods.contains(k));
    final streetCells = uniqueStreetCellKeysFromRoute(completed.route).toList();

    int collectedType(CoinType t) =>
        completed.coins.where((c) => c.isCollected && c.type == t).length;
    final gatesCaptured = completed.gates.where((g) => g.isCapture).length;
    final startedLocal = completed.startedAt.toLocal();
    final runWasEarlyBird = startedLocal.hour < 7;
    final runWasNightOwl = startedLocal.hour >= 21;

    final prevWeekTok = data['weeklyCoinsWeekToken'] as String?;
    final userUpdate = <String, dynamic>{
      'totalCoins': FieldValue.increment(collectedCoins),
      'totalDistance': FieldValue.increment(_distance),
      'totalRuns': FieldValue.increment(1),
      'weeklyRuns': FieldValue.arrayUnion([weekToken]),
      'currentStreakWeeks': streak,
      'longestStreakWeeks': longest,
      'explorerCoinsLifetime':
          FieldValue.increment(collectedType(CoinType.explorer)),
      'elevationCoinsLifetime':
          FieldValue.increment(collectedType(CoinType.elevation)),
      'phantomGoldLifetime':
          FieldValue.increment(collectedType(CoinType.phantomGold)),
      'gatesCapturedLifetime': FieldValue.increment(gatesCaptured),
      'streetbeatSessionsLifetime':
          FieldValue.increment(completed.streetbeatCount),
      'earlyBirdRuns': FieldValue.increment(runWasEarlyBird ? 1 : 0),
      'nightOwlRuns': FieldValue.increment(runWasNightOwl ? 1 : 0),
      'rainRuns': FieldValue.increment(0),
    };
    if (prevWeekTok != weekToken) {
      userUpdate['weeklyCoinsWeekToken'] = weekToken;
      userUpdate['weeklyCoins'] = collectedCoins;
      userUpdate['weeklyDistanceMeters'] = _distance;
    } else {
      userUpdate['weeklyCoins'] = FieldValue.increment(collectedCoins);
      userUpdate['weeklyDistanceMeters'] = FieldValue.increment(_distance);
    }
    final prevLongestRun = (data['longestRunMeters'] as num?)?.toDouble() ?? 0;
    if (_distance > prevLongestRun) {
      userUpdate['longestRunMeters'] = _distance;
    }
    final prevMaxCoins = (data['mostCoinsSingleRun'] as num?)?.toInt() ?? 0;
    if (collectedCoins > prevMaxCoins) {
      userUpdate['mostCoinsSingleRun'] = collectedCoins;
    }
    if (elapsedSec > 0 && _distance >= 100) {
      final pace = elapsedSec / (_distance / 1000.0);
      if (pace.isFinite && pace > 0) {
        final prevBest = (data['bestPaceSecPerKm'] as num?)?.toDouble();
        if (prevBest == null || pace < prevBest) {
          userUpdate['bestPaceSecPerKm'] = pace;
        }
      }
    }
    if (neighborhoodKeys.isNotEmpty) {
      userUpdate['neighborhoodCells'] = FieldValue.arrayUnion(neighborhoodKeys);
    }
    if (streetCells.isNotEmpty) {
      userUpdate['uniqueStreetCells'] = FieldValue.arrayUnion(streetCells);
    }

    final batch = _firestore.batch();
    batch.set(
      _firestore.collection('runs').doc(completed.id),
      completed.toFirestore(),
    );
    batch.update(userRef, userUpdate);
    await batch.commit();
    if (emit.isDone) {
      return;
    }

    var personalBestBeaten = false;
    if (_route.length >= 2 && elapsedSec > 0) {
      final ghost = ghostFromRoute(
        runId: completed.id,
        route: _route,
        durationMs: elapsedSec * 1000,
        totalDistance: _distance,
      );
      personalBestBeaten = await _ghostService.saveGhostIfBetter(
        uid: uid,
        segmentKey: _segmentKey,
        ghost: ghost,
        durationSeconds: elapsedSec,
        distanceMeters: _distance,
      );
    }
    if (personalBestBeaten) {
      await userRef.update({'ghostBeatsLifetime': FieldValue.increment(1)});
    }
    if (emit.isDone) {
      return;
    }

    final userSnapAfter = await userRef.get();
    final userModel = UserModel.fromFirestore(
      userSnapAfter.data() ?? {},
      runVisitedNewNeighborhood: runVisitedNewNeighborhood,
    );
    final newlyEarnedBadges =
        await _badgeService.checkAndAwardBadges(uid, completed, userModel);
    if (emit.isDone) {
      return;
    }

    await _firestore.collection('runs').doc(completed.id).update({
      'earnedBadgeIds': newlyEarnedBadges.map((e) => e.id).toList(),
    });

    final payload = RunSummaryPayload(
      run: completed,
      ghostRoute: ghostReplayPath,
      hadGhost: hadGhost,
      playerPaceSamples: playerPaceSamples,
      ghostPaceSamples: ghostPaceSamples,
      newBadgeIds: newlyEarnedBadges.map((e) => e.id).toList(),
      newlyEarnedBadges: newlyEarnedBadges,
      currentStreakWeeks: streak,
      previousStreakWeeks: previousStreakWeeks,
      weeklyGoalRuns: weeklyGoal,
      runsThisWeekAfterRun: runsThisWeekAfterRun,
      personalBestBeaten: personalBestBeaten,
    );

    _resetSession();
    emit(RunCompleted(payload));
  }
}
