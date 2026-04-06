import 'package:flutter_bloc/flutter_bloc.dart';

sealed class ProfileEvent {}

class ProfileStarted extends ProfileEvent {}

sealed class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc() : super(ProfileInitial()) {
    on<ProfileEvent>((_, emit) {});
  }
}
