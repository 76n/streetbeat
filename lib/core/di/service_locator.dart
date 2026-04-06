import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../shared/repositories/auth_repository.dart';
import '../../shared/services/firebase_service.dart';
import '../../shared/services/ghost_service.dart';
import '../../shared/services/location_service.dart';
import '../../shared/services/osm_service.dart';

final GetIt sl = GetIt.instance;

Future<void> configureDependencies() async {
  if (!sl.isRegistered<FirebaseService>()) {
    sl.registerLazySingleton<FirebaseService>(FirebaseService.new);
  }
  if (!sl.isRegistered<AuthRepository>()) {
    sl.registerLazySingleton<AuthRepository>(
      () => AuthRepository(
        firebaseAuth: FirebaseAuth.instance,
        googleSignIn: GoogleSignIn(
          scopes: const ['email', 'profile'],
        ),
        firestore: FirebaseFirestore.instance,
      ),
    );
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
