import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../features/run/bloc/run_bloc.dart';
import '../../shared/repositories/auth_repository.dart';
import '../../shared/repositories/social_repository.dart';
import '../../shared/services/badge_service.dart';
import '../../shared/services/firebase_service.dart';
import '../../shared/services/ghost_service.dart';
import '../../shared/services/local_notification_service.dart';
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
  if (!sl.isRegistered<SocialRepository>()) {
    sl.registerLazySingleton<SocialRepository>(
      () => SocialRepository(
        FirebaseFirestore.instance,
        functions: FirebaseFunctions.instanceFor(region: 'me-west1'),
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
    sl.registerLazySingleton<GhostService>(
      () => GhostService(FirebaseFirestore.instance),
    );
  }
  if (!sl.isRegistered<BadgeService>()) {
    sl.registerLazySingleton<BadgeService>(
      () => BadgeService(FirebaseFirestore.instance),
    );
  }
  if (!sl.isRegistered<LocalNotificationService>()) {
    sl.registerLazySingleton<LocalNotificationService>(
      LocalNotificationService.new,
    );
  }
  if (!sl.isRegistered<RunBloc>()) {
    sl.registerFactory<RunBloc>(
      () => RunBloc(
        osmService: sl<OsmService>(),
        ghostService: sl<GhostService>(),
        badgeService: sl<BadgeService>(),
        firestore: FirebaseFirestore.instance,
        auth: FirebaseAuth.instance,
        localNotifications: sl<LocalNotificationService>(),
      ),
    );
  }
  await sl<LocalNotificationService>().init();
}
