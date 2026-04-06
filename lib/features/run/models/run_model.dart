import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

import 'coin_model.dart';
import 'gate_model.dart';

class RunModel extends Equatable {
  const RunModel({
    required this.id,
    required this.uid,
    required this.startedAt,
    this.endedAt,
    this.distance = 0,
    this.durationSeconds = 0,
    this.averagePace,
    this.maxPace,
    this.elevationGain = 0,
    this.coins = const [],
    this.gates = const [],
    this.route = const [],
    this.totalScore = 0,
    this.maxMultiplier = 1,
    this.streetbeatCount = 0,
    this.ghostDelta = 0,
    this.earnedBadgeIds = const [],
    this.kudosUserIds = const [],
    this.kudosCount = 0,
    this.commentCount = 0,
    this.weekToken = '',
    this.runnerName = '',
    this.runnerCity = '',
    this.segmentKey = '',
  });

  final String id;
  final String uid;
  final DateTime startedAt;
  final DateTime? endedAt;
  final double distance;
  final int durationSeconds;
  final String? averagePace;
  final String? maxPace;
  final double elevationGain;
  final List<CoinModel> coins;
  final List<GateModel> gates;
  final List<LatLng> route;
  final int totalScore;
  final double maxMultiplier;
  final int streetbeatCount;
  final double ghostDelta;
  final List<String> earnedBadgeIds;
  final List<String> kudosUserIds;
  final int kudosCount;
  final int commentCount;
  final String weekToken;
  final String runnerName;
  final String runnerCity;
  final String segmentKey;

  RunModel copyWith({
    DateTime? endedAt,
    double? distance,
    int? durationSeconds,
    String? averagePace,
    String? maxPace,
    double? elevationGain,
    List<CoinModel>? coins,
    List<GateModel>? gates,
    List<LatLng>? route,
    int? totalScore,
    double? maxMultiplier,
    int? streetbeatCount,
    double? ghostDelta,
    List<String>? earnedBadgeIds,
    List<String>? kudosUserIds,
    int? kudosCount,
    int? commentCount,
    String? weekToken,
    String? runnerName,
    String? runnerCity,
    String? segmentKey,
  }) {
    return RunModel(
      id: id,
      uid: uid,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      distance: distance ?? this.distance,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      averagePace: averagePace ?? this.averagePace,
      maxPace: maxPace ?? this.maxPace,
      elevationGain: elevationGain ?? this.elevationGain,
      coins: coins ?? this.coins,
      gates: gates ?? this.gates,
      route: route ?? this.route,
      totalScore: totalScore ?? this.totalScore,
      maxMultiplier: maxMultiplier ?? this.maxMultiplier,
      streetbeatCount: streetbeatCount ?? this.streetbeatCount,
      ghostDelta: ghostDelta ?? this.ghostDelta,
      earnedBadgeIds: earnedBadgeIds ?? this.earnedBadgeIds,
      kudosUserIds: kudosUserIds ?? this.kudosUserIds,
      kudosCount: kudosCount ?? this.kudosCount,
      commentCount: commentCount ?? this.commentCount,
      weekToken: weekToken ?? this.weekToken,
      runnerName: runnerName ?? this.runnerName,
      runnerCity: runnerCity ?? this.runnerCity,
      segmentKey: segmentKey ?? this.segmentKey,
    );
  }

  @override
  List<Object?> get props => [
        id,
        uid,
        startedAt,
        endedAt,
        distance,
        durationSeconds,
        averagePace,
        maxPace,
        elevationGain,
        coins,
        gates,
        route,
        totalScore,
        maxMultiplier,
        streetbeatCount,
        ghostDelta,
        earnedBadgeIds,
        kudosUserIds,
        kudosCount,
        commentCount,
        weekToken,
        runnerName,
        runnerCity,
        segmentKey,
      ];

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'uid': uid,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'distance': distance,
      'durationSeconds': durationSeconds,
      'averagePace': averagePace,
      'maxPace': maxPace,
      'elevationGain': elevationGain,
      'coins': coins.map((e) => e.toFirestore()).toList(),
      'gates': gates.map((e) => e.toFirestore()).toList(),
      'route':
          route.map((e) => {'lat': e.latitude, 'lng': e.longitude}).toList(),
      'totalScore': totalScore,
      'maxMultiplier': maxMultiplier,
      'streetbeatCount': streetbeatCount,
      'ghostDelta': ghostDelta,
      'earnedBadgeIds': earnedBadgeIds,
      'kudosUserIds': kudosUserIds,
      'kudosCount': kudosCount,
      'commentCount': commentCount,
      'weekToken': weekToken,
      'runnerName': runnerName,
      'runnerCity': runnerCity,
      'segmentKey': segmentKey,
    };
  }

  static List<LatLng> _parseRoute(List<dynamic>? raw) {
    if (raw == null) {
      return [];
    }
    final out = <LatLng>[];
    for (final e in raw) {
      if (e is! Map) {
        continue;
      }
      final lat = e['lat'] as num?;
      final lng = e['lng'] as num?;
      if (lat != null && lng != null) {
        out.add(LatLng(lat.toDouble(), lng.toDouble()));
      }
    }
    return out;
  }

  static RunModel fromFirestore(String id, Map<String, dynamic> m) {
    final coinsRaw = m['coins'] as List<dynamic>?;
    final coins = <CoinModel>[];
    if (coinsRaw != null) {
      for (final e in coinsRaw) {
        if (e is Map<String, dynamic>) {
          final c = CoinModel.tryFromFirestore(e);
          if (c != null) {
            coins.add(c);
          }
        }
      }
    }
    final gatesRaw = m['gates'] as List<dynamic>?;
    final gates = <GateModel>[];
    if (gatesRaw != null) {
      for (final e in gatesRaw) {
        if (e is Map<String, dynamic>) {
          final g = GateModel.tryFromFirestore(e);
          if (g != null) {
            gates.add(g);
          }
        }
      }
    }
    final started =
        DateTime.tryParse(m['startedAt'] as String? ?? '') ?? DateTime.now();
    return RunModel(
      id: m['id'] as String? ?? id,
      uid: m['uid'] as String? ?? '',
      startedAt: started,
      endedAt: DateTime.tryParse(m['endedAt'] as String? ?? ''),
      distance: (m['distance'] as num?)?.toDouble() ?? 0,
      durationSeconds: (m['durationSeconds'] as num?)?.toInt() ?? 0,
      averagePace: m['averagePace'] as String?,
      maxPace: m['maxPace'] as String?,
      elevationGain: (m['elevationGain'] as num?)?.toDouble() ?? 0,
      coins: coins,
      gates: gates,
      route: _parseRoute(m['route'] as List<dynamic>?),
      totalScore: (m['totalScore'] as num?)?.toInt() ?? 0,
      maxMultiplier: (m['maxMultiplier'] as num?)?.toDouble() ?? 1,
      streetbeatCount: (m['streetbeatCount'] as num?)?.toInt() ?? 0,
      ghostDelta: (m['ghostDelta'] as num?)?.toDouble() ?? 0,
      earnedBadgeIds: (m['earnedBadgeIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      kudosUserIds: (m['kudosUserIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      kudosCount: (m['kudosCount'] as num?)?.toInt() ?? 0,
      commentCount: (m['commentCount'] as num?)?.toInt() ?? 0,
      weekToken: m['weekToken'] as String? ?? '',
      runnerName: m['runnerName'] as String? ?? '',
      runnerCity: m['runnerCity'] as String? ?? '',
      segmentKey: m['segmentKey'] as String? ?? '',
    );
  }
}
