import 'package:flutter_bloc/flutter_bloc.dart';

sealed class FeedEvent {}

class FeedStarted extends FeedEvent {}

sealed class FeedState {}

class FeedInitial extends FeedState {}

class FeedBloc extends Bloc<FeedEvent, FeedState> {
  FeedBloc() : super(FeedInitial()) {
    on<FeedEvent>((_, emit) {});
  }
}
