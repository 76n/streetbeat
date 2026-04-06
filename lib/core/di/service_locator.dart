import 'package:get_it/get_it.dart';

import '../../shared/services/firebase_service.dart';
import '../../shared/services/ghost_service.dart';
import '../../shared/services/location_service.dart';
import '../../shared/services/osm_service.dart';

final GetIt sl = GetIt.instance;

Future<void> configureDependencies() async {
  if (!sl.isRegistered<FirebaseService>()) {
    sl.registerLazySingleton<FirebaseService>(FirebaseService.new);
  }
  if (!sl.isRegistered<LocationService>()) {
    sl.registerLazySingleton<LocationService>(LocationService.new);
  }
  if (!sl.isRegistered<OsmService>()) {
    sl.registerLazySingleton<OsmService>(OsmService.new);
  }
  if (!sl.isRegistered<GhostService>()) {
    sl.registerLazySingleton<GhostService>(GhostService.new);
  }
}
