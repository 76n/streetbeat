import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

import '../../../shared/models/badge_model.dart';
import 'run_model.dart';

class PaceSample extends Equatable {
  const PaceSample(this.distanceMeters, this.paceSecPerKm);

  final double distanceMeters;
  final double paceSecPerKm;

  @override
  List<Object?> get props => [distanceMeters, paceSecPerKm];
}

class RunSummaryPayload extends Equatable {
  const RunSummaryPayload({
    required this.run,
    this.ghostRoute = const [],
    this.hadGhost = false,
    this.playerPaceSamples = const [],
    this.ghostPaceSamples = const [],
    this.newBadgeIds = const [],
    this.newlyEarnedBadges = const [],
    this.currentStreakWeeks = 0,
    this.previousStreakWeeks = 0,
    this.weeklyGoalRuns = 3,
    this.runsThisWeekAfterRun = 1,
    this.personalBestBeaten = false,
  });

  final RunModel run;
  final List<LatLng> ghostRoute;
  final bool hadGhost;
  final List<PaceSample> playerPaceSamples;
  final List<PaceSample> ghostPaceSamples;
  final List<String> newBadgeIds;
  final List<BadgeModel> newlyEarnedBadges;
  final int currentStreakWeeks;
  final int previousStreakWeeks;
  final int weeklyGoalRuns;
  final int runsThisWeekAfterRun;
  final bool personalBestBeaten;

  @override
  List<Object?> get props => [
        run,
        ghostRoute,
        hadGhost,
        playerPaceSamples,
        ghostPaceSamples,
        newBadgeIds,
        newlyEarnedBadges,
        currentStreakWeeks,
        previousStreakWeeks,
        weeklyGoalRuns,
        runsThisWeekAfterRun,
        personalBestBeaten,
      ];
}
