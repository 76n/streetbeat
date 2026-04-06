import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/activity_type.dart';
import '../models/race_goal_option.dart';
import '../models/weekly_goal_runs.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class AuthUserSynced extends AuthEvent {
  const AuthUserSynced(this.user);

  final User? user;

  @override
  List<Object?> get props => [user?.uid];
}

class AuthSignInEmail extends AuthEvent {
  const AuthSignInEmail({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class AuthSignInGoogle extends AuthEvent {
  const AuthSignInGoogle();
}

class AuthSignUp extends AuthEvent {
  const AuthSignUp({
    required this.name,
    required this.email,
    required this.password,
    required this.activityType,
    required this.weeklyGoalRuns,
    required this.raceGoal,
  });

  final String name;
  final String email;
  final String password;
  final ActivityType activityType;
  final WeeklyGoalRuns weeklyGoalRuns;
  final RaceGoalOption raceGoal;

  @override
  List<Object?> get props => [
        name,
        email,
        password,
        activityType,
        weeklyGoalRuns,
        raceGoal,
      ];
}

class AuthSignOut extends AuthEvent {
  const AuthSignOut();
}
