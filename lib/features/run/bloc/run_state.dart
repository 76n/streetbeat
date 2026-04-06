import 'package:equatable/equatable.dart';

abstract class RunState extends Equatable {
  const RunState();

  @override
  List<Object?> get props => [];
}

class RunInitial extends RunState {
  const RunInitial();
}
