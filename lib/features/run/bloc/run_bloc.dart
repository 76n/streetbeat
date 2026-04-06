import 'package:flutter_bloc/flutter_bloc.dart';

import 'run_event.dart';
import 'run_state.dart';

class RunBloc extends Bloc<RunEvent, RunState> {
  RunBloc() : super(const RunInitial()) {
    on<RunEvent>((_, emit) {});
  }
}
