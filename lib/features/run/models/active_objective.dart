import 'package:equatable/equatable.dart';

enum ObjectiveKind {
  hitGates,
  collectCoins,
  maintainPace,
  reachKm,
}

class ActiveObjective extends Equatable {
  const ActiveObjective({
    required this.kind,
    required this.target,
    required this.progress,
    this.paceWindowEndsAt,
  });

  final ObjectiveKind kind;
  final int target;
  final int progress;
  final DateTime? paceWindowEndsAt;

  ActiveObjective copyWith({
    int? progress,
    DateTime? paceWindowEndsAt,
  }) {
    return ActiveObjective(
      kind: kind,
      target: target,
      progress: progress ?? this.progress,
      paceWindowEndsAt: paceWindowEndsAt ?? this.paceWindowEndsAt,
    );
  }

  bool get isComplete => progress >= target;

  String get label {
    return switch (kind) {
      ObjectiveKind.hitGates => 'Hit $target more gates',
      ObjectiveKind.collectCoins => 'Collect $target coins',
      ObjectiveKind.maintainPace => 'Hold pace for 1 min',
      ObjectiveKind.reachKm => 'Reach next km',
    };
  }

  @override
  List<Object?> get props => [kind, target, progress, paceWindowEndsAt];
}
