import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

abstract final class LocationUtils {
  static const double earthRadiusM = 6371000;

  static double bearing(LatLng from, LatLng to) {
    final lat1 = from.latitude * math.pi / 180;
    final lat2 = to.latitude * math.pi / 180;
    final dLon = (to.longitude - from.longitude) * math.pi / 180;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final brng = math.atan2(y, x) * 180 / math.pi;
    return (brng + 360) % 360;
  }

  static double distanceMeters(LatLng a, LatLng b) {
    final lat1 = a.latitude * math.pi / 180;
    final lat2 = b.latitude * math.pi / 180;
    final dLat = (b.latitude - a.latitude) * math.pi / 180;
    final dLon = (b.longitude - a.longitude) * math.pi / 180;
    final sinDLat = math.sin(dLat / 2);
    final sinDLon = math.sin(dLon / 2);
    final h =
        sinDLat * sinDLat + math.cos(lat1) * math.cos(lat2) * sinDLon * sinDLon;
    final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
    return earthRadiusM * c;
  }

  static LatLng pointOnBearing(
      LatLng origin, double bearingDeg, double distanceM) {
    final brng = bearingDeg * math.pi / 180;
    final lat1 = origin.latitude * math.pi / 180;
    final lon1 = origin.longitude * math.pi / 180;
    final dr = distanceM / earthRadiusM;
    final lat2 = math.asin(
      math.sin(lat1) * math.cos(dr) +
          math.cos(lat1) * math.sin(dr) * math.cos(brng),
    );
    final lon2 = lon1 +
        math.atan2(
          math.sin(brng) * math.sin(dr) * math.cos(lat1),
          math.cos(dr) - math.sin(lat1) * math.sin(lat2),
        );
    return LatLng(lat2 * 180 / math.pi, lon2 * 180 / math.pi);
  }

  static double angleDiffDeg(double a, double b) {
    var d = a - b;
    while (d > 180) {
      d -= 360;
    }
    while (d < -180) {
      d += 360;
    }
    return d;
  }

  static bool isPointAhead(
    LatLng current,
    double bearingDeg,
    LatLng point,
    double toleranceDeg,
  ) {
    final toPoint = bearing(current, point);
    return angleDiffDeg(toPoint, bearingDeg).abs() <= toleranceDeg;
  }

  static String formatPace(double metersPerSecond) {
    if (metersPerSecond < 0.1 || !metersPerSecond.isFinite) {
      return '—';
    }
    final secPerKm = 1000.0 / metersPerSecond;
    if (!secPerKm.isFinite || secPerKm > 999 * 60) {
      return '—';
    }
    final totalSec = secPerKm.round();
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    return '$m:${s.toString().padLeft(2, '0')} /km';
  }

  static String formatDistance(double meters) {
    if (meters < 0 || !meters.isFinite) {
      return '0 m';
    }
    if (meters >= 1000) {
      final km = meters / 1000;
      return '${km.toStringAsFixed(km >= 10 ? 0 : 1)} km';
    }
    return '${meters.round()} m';
  }

  static LatLng closestPointOnSegment(LatLng a, LatLng b, LatLng p) {
    final mlat = 110574.0;
    final mlon = 111320.0 * math.cos(p.latitude * math.pi / 180);
    double x(LatLng l) => (l.longitude - p.longitude) * mlon;
    double y(LatLng l) => (l.latitude - p.latitude) * mlat;
    final ax = x(a);
    final ay = y(a);
    final bx = x(b);
    final by = y(b);
    final abx = bx - ax;
    final aby = by - ay;
    final t =
        ((0 - ax) * abx + (0 - ay) * aby) / (abx * abx + aby * aby + 1e-12);
    final tc = t.clamp(0.0, 1.0);
    final cx = ax + tc * abx;
    final cy = ay + tc * aby;
    return LatLng(p.latitude + cy / mlat, p.longitude + cx / mlon);
  }

  static double distanceToSegmentMeters(LatLng a, LatLng b, LatLng p) {
    final q = closestPointOnSegment(a, b, p);
    return distanceMeters(p, q);
  }

  static bool pointInPolygon(LatLng point, List<LatLng> polygon) {
    if (polygon.length < 3) {
      return false;
    }
    final x = point.longitude;
    final y = point.latitude;
    var inside = false;
    var j = polygon.length - 1;
    for (var i = 0; i < polygon.length; j = i++) {
      final xi = polygon[i].longitude;
      final yi = polygon[i].latitude;
      final xj = polygon[j].longitude;
      final yj = polygon[j].latitude;
      final intersect = ((yi > y) != (yj > y)) &&
          (x < (xj - xi) * (y - yi) / (yj - yi + 1e-20) + xi);
      if (intersect) {
        inside = !inside;
      }
    }
    return inside;
  }
}
