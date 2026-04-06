import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/location_utils.dart';

enum MotionActivity {
  running,
  walking,
  stopped,
}

class LocationSessionSnapshot {
  const LocationSessionSnapshot({
    required this.position,
    required this.speedMetersPerSecond,
    required this.bearingDegrees,
    required this.distanceTraveledMeters,
    required this.paceFormatted,
    required this.activity,
    required this.compressedRecordedPath,
    required this.timestamp,
  });

  final LatLng position;
  final double speedMetersPerSecond;
  final double bearingDegrees;
  final double distanceTraveledMeters;
  final String paceFormatted;
  final MotionActivity activity;
  final List<LatLng> compressedRecordedPath;
  final DateTime timestamp;
}

class LocationServiceException implements Exception {
  LocationServiceException(this.message);
  final String message;

  @override
  String toString() => 'LocationServiceException: $message';
}

class LocationService {
  static const _prefsFirstPromptKey = 'sb_location_permission_prompt_v1';

  LocationSettings _buildPlatformSettings() {
    if (kIsWeb) {
      return const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
      );
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 1),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'StreetBeat',
          notificationText: 'Tracking your location',
          notificationChannelName: 'StreetBeat location',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: false,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 0,
    );
  }

  Future<void> requestPermissionsOnFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    final already = prefs.getBool(_prefsFirstPromptKey) ?? false;
    if (!already) {
      await prefs.setBool(_prefsFirstPromptKey, true);
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      var loc = await Permission.location.status;
      if (loc.isDenied) {
        loc = await Permission.location.request();
      }
      if (loc.isGranted || loc.isLimited) {
        final always = await Permission.locationAlways.status;
        if (!always.isGranted) {
          await Permission.locationAlways.request();
        }
      }
    }

    var g = await Geolocator.checkPermission();
    if (g == LocationPermission.denied) {
      g = await Geolocator.requestPermission();
    }
  }

  Future<bool> ensureTrackingReady() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return false;
    }

    if (!kIsWeb) {
      var loc = await Permission.location.status;
      if (loc.isDenied) {
        loc = await Permission.location.request();
      }
      if (!loc.isGranted && !loc.isLimited) {
        return false;
      }
    }

    var g = await Geolocator.checkPermission();
    if (g == LocationPermission.denied) {
      g = await Geolocator.requestPermission();
    }
    if (g == LocationPermission.denied ||
        g == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Stream<LocationSessionSnapshot> watchSession() async* {
    final ok = await ensureTrackingReady();
    if (!ok) {
      throw LocationServiceException(
        'Location permission denied or location services are disabled.',
      );
    }

    var distanceTraveled = 0.0;
    final recorded = <LatLng>[];
    LatLng? lastRecorded;
    Position? prevAccepted;
    var lastMoving = MotionActivity.walking;
    DateTime? belowHalfSince;
    var lastBearing = 0.0;

    final settings = _buildPlatformSettings();
    var lastEmit = DateTime.fromMillisecondsSinceEpoch(0);

    await for (final pos in Geolocator.getPositionStream(
      locationSettings: settings,
    )) {
      final now = DateTime.now();
      if (now.difference(lastEmit) < const Duration(seconds: 1)) {
        continue;
      }
      lastEmit = now;

      final current = LatLng(pos.latitude, pos.longitude);

      var speed = pos.speed;
      if (speed < 0 || speed.isNaN) {
        if (prevAccepted != null) {
          final moved = LocationUtils.distanceMeters(
            LatLng(prevAccepted.latitude, prevAccepted.longitude),
            current,
          );
          speed = moved;
        } else {
          speed = 0;
        }
      }

      if (prevAccepted != null) {
        distanceTraveled += LocationUtils.distanceMeters(
          LatLng(prevAccepted.latitude, prevAccepted.longitude),
          current,
        );
      }

      double bear;
      final prev = prevAccepted;
      final movedForBearing = prev != null
          ? LocationUtils.distanceMeters(
              LatLng(prev.latitude, prev.longitude),
              current,
            )
          : 0.0;
      if (prev != null && movedForBearing > 2) {
        bear = LocationUtils.bearing(
          LatLng(prev.latitude, prev.longitude),
          current,
        );
      } else if (pos.heading > 0.01) {
        bear = pos.heading % 360;
      } else {
        bear = lastBearing;
      }
      lastBearing = bear;

      final pace = LocationUtils.formatPace(speed);

      MotionActivity activity;
      if (speed > 2) {
        belowHalfSince = null;
        activity = MotionActivity.running;
        lastMoving = MotionActivity.running;
      } else if (speed >= 0.5) {
        belowHalfSince = null;
        activity = MotionActivity.walking;
        lastMoving = MotionActivity.walking;
      } else {
        final since = belowHalfSince ?? now;
        belowHalfSince = since;
        if (now.difference(since) >= const Duration(seconds: 30)) {
          activity = MotionActivity.stopped;
        } else {
          activity = lastMoving;
        }
      }

      if (lastRecorded == null ||
          LocationUtils.distanceMeters(lastRecorded, current) >= 3) {
        recorded.add(current);
        lastRecorded = current;
      }

      prevAccepted = pos;

      yield LocationSessionSnapshot(
        position: current,
        speedMetersPerSecond: speed,
        bearingDegrees: bear,
        distanceTraveledMeters: distanceTraveled,
        paceFormatted: pace,
        activity: activity,
        compressedRecordedPath: List<LatLng>.from(recorded),
        timestamp: now,
      );
    }
  }
}
