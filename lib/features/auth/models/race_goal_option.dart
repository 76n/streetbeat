enum RaceGoalOption {
  none,
  k5,
  k10,
  halfMarathon,
  marathon,
}

extension RaceGoalOptionFirestore on RaceGoalOption {
  String? get asFirestoreValue => switch (this) {
        RaceGoalOption.none => null,
        RaceGoalOption.k5 => '5k',
        RaceGoalOption.k10 => '10k',
        RaceGoalOption.halfMarathon => 'half_marathon',
        RaceGoalOption.marathon => 'marathon',
      };

  String get label => switch (this) {
        RaceGoalOption.none => 'None',
        RaceGoalOption.k5 => '5K',
        RaceGoalOption.k10 => '10K',
        RaceGoalOption.halfMarathon => 'Half Marathon',
        RaceGoalOption.marathon => 'Full Marathon',
      };
}
