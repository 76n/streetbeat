import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:streetbeat/core/utils/location_utils.dart';

void main() {
  group('bearing', () {
    test('north', () {
      final from = const LatLng(0, 0);
      final to = const LatLng(1, 0);
      expect(LocationUtils.bearing(from, to), closeTo(0, 0.5));
    });

    test('east', () {
      final from = const LatLng(0, 0);
      final to = const LatLng(0, 1);
      expect(LocationUtils.bearing(from, to), closeTo(90, 0.5));
    });

    test('south', () {
      final from = const LatLng(0, 0);
      final to = const LatLng(-1, 0);
      expect(LocationUtils.bearing(from, to), closeTo(180, 0.5));
    });

    test('west', () {
      final from = const LatLng(0, 0);
      final to = const LatLng(0, -1);
      expect(LocationUtils.bearing(from, to), closeTo(270, 0.5));
    });
  });

  group('distanceMeters', () {
    test('zero for same point', () {
      final p = const LatLng(52.5, 13.4);
      expect(LocationUtils.distanceMeters(p, p), 0);
    });

    test('approximate known separation', () {
      final a = const LatLng(52.52, 13.405);
      final b = const LatLng(52.53, 13.405);
      final d = LocationUtils.distanceMeters(a, b);
      expect(d, greaterThan(1000));
      expect(d, lessThan(1300));
    });
  });

  group('pointOnBearing', () {
    test('distance from origin matches requested', () {
      final o = const LatLng(52.5, 13.4);
      const dist = 250.0;
      final p = LocationUtils.pointOnBearing(o, 0, dist);
      final got = LocationUtils.distanceMeters(o, p);
      expect(got, closeTo(dist, 5));
    });

    test('bearing from origin to point matches (north)', () {
      final o = const LatLng(48.0, 2.0);
      final p = LocationUtils.pointOnBearing(o, 0, 500);
      final b = LocationUtils.bearing(o, p);
      expect(b, closeTo(0, 1));
    });
  });

  group('angleDiffDeg / isPointAhead', () {
    test('angleDiffDeg wraps', () {
      expect(LocationUtils.angleDiffDeg(10, 350), closeTo(20, 0.01));
      expect(LocationUtils.angleDiffDeg(350, 10), closeTo(-20, 0.01));
    });

    test('point straight ahead', () {
      final cur = const LatLng(52.5, 13.4);
      final ahead = LocationUtils.pointOnBearing(cur, 90, 80);
      expect(
        LocationUtils.isPointAhead(cur, 90, ahead, 60),
        isTrue,
      );
    });

    test('point behind cone rejected', () {
      final cur = const LatLng(52.5, 13.4);
      final behind = LocationUtils.pointOnBearing(cur, 270, 80);
      expect(
        LocationUtils.isPointAhead(cur, 90, behind, 60),
        isFalse,
      );
    });
  });

  group('formatPace', () {
    test('returns em dash for very low speed', () {
      expect(LocationUtils.formatPace(0), '—');
      expect(LocationUtils.formatPace(0.05), '—');
    });

    test('formats ~5:32 /km for ~3.01 m/s', () {
      final v = 1000.0 / 332.0;
      expect(LocationUtils.formatPace(v), '5:32 /km');
    });

    test('handles round minute', () {
      final v = 1000.0 / 300.0;
      expect(LocationUtils.formatPace(v), '5:00 /km');
    });
  });

  group('formatDistance', () {
    test('meters', () {
      expect(LocationUtils.formatDistance(0), '0 m');
      expect(LocationUtils.formatDistance(850), '850 m');
    });

    test('kilometers', () {
      expect(LocationUtils.formatDistance(3200), '3.2 km');
      expect(LocationUtils.formatDistance(10000), '10 km');
    });
  });

  group('closestPointOnSegment / distanceToSegmentMeters', () {
    test('projects to interior of segment', () {
      final a = const LatLng(0, 0);
      final b = const LatLng(0, 0.02);
      final p = const LatLng(0.001, 0.01);
      final q = LocationUtils.closestPointOnSegment(a, b, p);
      final dSeg = LocationUtils.distanceToSegmentMeters(a, b, p);
      final dQ = LocationUtils.distanceMeters(p, q);
      expect(dSeg, closeTo(dQ, 0.5));
      expect(
        LocationUtils.distanceMeters(q, const LatLng(0, 0.01)),
        lessThan(LocationUtils.distanceMeters(p, const LatLng(0, 0.01))),
      );
    });
  });

  group('pointInPolygon', () {
    test('inside square', () {
      final poly = [
        const LatLng(0, 0),
        const LatLng(0, 1),
        const LatLng(1, 1),
        const LatLng(1, 0),
        const LatLng(0, 0),
      ];
      expect(LocationUtils.pointInPolygon(const LatLng(0.5, 0.5), poly), isTrue);
      expect(LocationUtils.pointInPolygon(const LatLng(2, 2), poly), isFalse);
    });

    test('too few points', () {
      expect(
        LocationUtils.pointInPolygon(
          const LatLng(0, 0),
          [const LatLng(0, 0), const LatLng(1, 0)],
        ),
        isFalse,
      );
    });
  });
}
