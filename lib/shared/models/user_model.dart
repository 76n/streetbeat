import 'package:equatable/equatable.dart';

import 'badge_model.dart';

class UserModel extends Equatable {
  const UserModel({
    required this.name,
    required this.email,
    required this.city,
    required this.totalCoins,
    required this.totalDistance,
    required this.totalRuns,
    required this.currentStreakWeeks,
    required this.explorerCoinsLifetime,
    required this.elevationCoinsLifetime,
    required this.phantomGoldLifetime,
    required this.gatesCapturedLifetime,
    required this.streetbeatSessionsLifetime,
    required this.ghostBeatsLifetime,
    required this.earlyBirdRuns,
    required this.nightOwlRuns,
    required this.rainRuns,
    required this.neighborhoodCells,
    required this.uniqueStreetCells,
    required this.badges,
    required this.friends,
    required this.weeklyRuns,
    required this.weeklyGoalRuns,
    required this.weeklyCoins,
    required this.weeklyCoinsWeekToken,
    required this.weeklyDistanceMeters,
    required this.bestPaceSecPerKm,
    required this.longestRunMeters,
    required this.mostCoinsSingleRun,
    this.runVisitedNewNeighborhood = false,
  });

  final String name;
  final String email;
  final String city;
  final int totalCoins;
  final double totalDistance;
  final int totalRuns;
  final int currentStreakWeeks;
  final int explorerCoinsLifetime;
  final int elevationCoinsLifetime;
  final int phantomGoldLifetime;
  final int gatesCapturedLifetime;
  final int streetbeatSessionsLifetime;
  final int ghostBeatsLifetime;
  final int earlyBirdRuns;
  final int nightOwlRuns;
  final int rainRuns;
  final List<String> neighborhoodCells;
  final List<String> uniqueStreetCells;
  final List<BadgeModel> badges;
  final List<String> friends;
  final List<String> weeklyRuns;
  final int weeklyGoalRuns;
  final int weeklyCoins;
  final String weeklyCoinsWeekToken;
  final double weeklyDistanceMeters;
  final double? bestPaceSecPerKm;
  final double longestRunMeters;
  final int mostCoinsSingleRun;
  final bool runVisitedNewNeighborhood;

  int runsCountForWeekToken(String weekToken) =>
      weeklyRuns.where((w) => w == weekToken).length;

  factory UserModel.fromFirestore(
    Map<String, dynamic> data, {
    bool runVisitedNewNeighborhood = false,
  }) {
    return UserModel(
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      city: data['city'] as String? ?? '',
      totalCoins: (data['totalCoins'] as num?)?.toInt() ?? 0,
      totalDistance: (data['totalDistance'] as num?)?.toDouble() ?? 0,
      totalRuns: (data['totalRuns'] as num?)?.toInt() ?? 0,
      currentStreakWeeks: (data['currentStreakWeeks'] as num?)?.toInt() ?? 0,
      explorerCoinsLifetime:
          (data['explorerCoinsLifetime'] as num?)?.toInt() ?? 0,
      elevationCoinsLifetime:
          (data['elevationCoinsLifetime'] as num?)?.toInt() ?? 0,
      phantomGoldLifetime: (data['phantomGoldLifetime'] as num?)?.toInt() ?? 0,
      gatesCapturedLifetime:
          (data['gatesCapturedLifetime'] as num?)?.toInt() ?? 0,
      streetbeatSessionsLifetime:
          (data['streetbeatSessionsLifetime'] as num?)?.toInt() ?? 0,
      ghostBeatsLifetime: (data['ghostBeatsLifetime'] as num?)?.toInt() ?? 0,
      earlyBirdRuns: (data['earlyBirdRuns'] as num?)?.toInt() ?? 0,
      nightOwlRuns: (data['nightOwlRuns'] as num?)?.toInt() ?? 0,
      rainRuns: (data['rainRuns'] as num?)?.toInt() ?? 0,
      neighborhoodCells: (data['neighborhoodCells'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      uniqueStreetCells: (data['uniqueStreetCells'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      badges: BadgeModel.parseList(data['badges']),
      friends: (data['friends'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      weeklyRuns: (data['weeklyRuns'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      weeklyGoalRuns: (data['weeklyGoalRuns'] as num?)?.toInt() ?? 3,
      weeklyCoins: (data['weeklyCoins'] as num?)?.toInt() ?? 0,
      weeklyCoinsWeekToken: data['weeklyCoinsWeekToken'] as String? ?? '',
      weeklyDistanceMeters:
          (data['weeklyDistanceMeters'] as num?)?.toDouble() ?? 0,
      bestPaceSecPerKm: (data['bestPaceSecPerKm'] as num?)?.toDouble(),
      longestRunMeters: (data['longestRunMeters'] as num?)?.toDouble() ?? 0,
      mostCoinsSingleRun: (data['mostCoinsSingleRun'] as num?)?.toInt() ?? 0,
      runVisitedNewNeighborhood: runVisitedNewNeighborhood,
    );
  }

  @override
  List<Object?> get props => [
        name,
        email,
        city,
        totalCoins,
        totalDistance,
        totalRuns,
        currentStreakWeeks,
        explorerCoinsLifetime,
        elevationCoinsLifetime,
        phantomGoldLifetime,
        gatesCapturedLifetime,
        streetbeatSessionsLifetime,
        ghostBeatsLifetime,
        earlyBirdRuns,
        nightOwlRuns,
        rainRuns,
        neighborhoodCells,
        uniqueStreetCells,
        badges,
        friends,
        weeklyRuns,
        weeklyGoalRuns,
        weeklyCoins,
        weeklyCoinsWeekToken,
        weeklyDistanceMeters,
        bestPaceSecPerKm,
        longestRunMeters,
        mostCoinsSingleRun,
        runVisitedNewNeighborhood,
      ];
}
