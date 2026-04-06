import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

import '../../../shared/services/location_service.dart';
import '../models/ghost_model.dart';

abstract class RunEvent extends Equatable {
  const RunEvent();

  @override
  List<Object?> get props => [];
}

class RunStarted extends RunEvent {
  const RunStarted({
    required this.position,
    required this.bearing,
  });

  final LatLng position;
  final double bearing;

  @override
  List<Object?> get props => [position, bearing];
}

class RunPaused extends RunEvent {
  const RunPaused();
}

class RunResumed extends RunEvent {
  const RunResumed();
}

class RunStopped extends RunEvent {
  const RunStopped();
}

class LocationUpdated extends RunEvent {
  const LocationUpdated({
    required this.position,
    required this.speed,
    required this.bearing,
    required this.activity,
    required this.distanceTraveled,
    required this.routeCompressed,
  });

  final LatLng position;
  final double speed;
  final double bearing;
  final MotionActivity activity;
  final double distanceTraveled;
  final List<LatLng> routeCompressed;

  @override
  List<Object?> get props =>
      [position, speed, bearing, activity, distanceTraveled, routeCompressed];
}

class CoinCollected extends RunEvent {
  const CoinCollected(this.coinId);

  final String coinId;

  @override
  List<Object?> get props => [coinId];
}

class GateCapture extends RunEvent {
  const GateCapture(this.gateId);

  final String gateId;

  @override
  List<Object?> get props => [gateId];
}

class GateMissed extends RunEvent {
  const GateMissed(this.gateId);

  final String gateId;

  @override
  List<Object?> get props => [gateId];
}

class GhostLoaded extends RunEvent {
  const GhostLoaded(this.ghost);

  final GhostModel ghost;

  @override
  List<Object?> get props => [ghost];
}

class RunCelebrationAcknowledged extends RunEvent {
  const RunCelebrationAcknowledged();
}
