import 'package:equatable/equatable.dart';

abstract class RunEvent extends Equatable {
  const RunEvent();

  @override
  List<Object?> get props => [];
}

class RunStarted extends RunEvent {
  const RunStarted();
}
