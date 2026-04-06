import 'package:equatable/equatable.dart';

import '../models/active_objective.dart';
import '../models/coin_model.dart';
import '../models/gate_model.dart';
import '../models/ghost_model.dart';
import '../models/run_model.dart';
import '../models/run_summary_payload.dart';

enum RunCelebrationKind {
  playerPassedGhost,
  ghostPassedPlayer,
  objectiveComplete,
}

class RunSessionData extends Equatable {
  const RunSessionData({
    required this.run,
    required this.coins,
    required this.gates,
    required this.multiplier,
    required this.ghostDeltaSeconds,
    required this.streetbeatActive,
    this.streetbeatEndsAt,
    required this.activeObjective,
    this.ghost,
  });

  final RunModel run;
  final List<CoinModel> coins;
  final List<GateModel> gates;
  final double multiplier;
  final double ghostDeltaSeconds;
  final bool streetbeatActive;
  final DateTime? streetbeatEndsAt;
  final ActiveObjective activeObjective;
  final GhostModel? ghost;

  @override
  List<Object?> get props => [
        run,
        coins,
        gates,
        multiplier,
        ghostDeltaSeconds,
        streetbeatActive,
        streetbeatEndsAt,
        activeObjective,
        ghost,
      ];
}

abstract class RunState extends Equatable {
  const RunState();

  @override
  List<Object?> get props => [];
}

class RunIdle extends RunState {
  const RunIdle();
}

class RunActive extends RunState {
  const RunActive(
    this.data, {
    this.celebration,
  });

  final RunSessionData data;
  final RunCelebrationKind? celebration;

  @override
  List<Object?> get props => [data, celebration];
}

class RunPaused extends RunState {
  const RunPaused(this.data);

  final RunSessionData data;

  @override
  List<Object?> get props => [data];
}

class RunCompleted extends RunState {
  const RunCompleted(this.payload);

  final RunSummaryPayload payload;

  @override
  List<Object?> get props => [payload];
}

class RunFailure extends RunState {
  const RunFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
