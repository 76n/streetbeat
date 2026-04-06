import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../core/utils/location_utils.dart';

class _CachedPaths {
  _CachedPaths(this.segments, this.fetchedAt);

  final List<List<LatLng>> segments;
  final DateTime fetchedAt;
}

class _CachedBuildings {
  _CachedBuildings(this.polygons, this.fetchedAt);

  final List<List<LatLng>> polygons;
  final DateTime fetchedAt;
}

class OsmService {
  OsmService({http.Client? httpClient}) : _client = httpClient ?? http.Client();

  final http.Client _client;

  static const _cacheTtl = Duration(minutes: 5);
  static const _overpassUrl = 'https://overpass-api.de/api/interpreter';

  final Map<String, _CachedPaths> _pathCache = {};
  final Map<String, _CachedBuildings> _buildingCache = {};

  List<List<LatLng>> _lastPathSegments = [];

  String _cacheKey(LatLng c, double radiusMeters) {
    final lat = (c.latitude * 200).round() / 200;
    final lon = (c.longitude * 200).round() / 200;
    return '${lat.toStringAsFixed(3)}_${lon.toStringAsFixed(3)}_${radiusMeters.round()}';
  }

  String _overpassHighwayQuery(LatLng center, double radiusMeters) {
    final lat = center.latitude;
    final lon = center.longitude;
    final r = radiusMeters.ceil();
    return '''
[out:json][timeout:25];
(
  way["highway"~"^(footway|path|pedestrian|residential|living_street|track)\$"](around:$r,$lat,$lon);
);
out geom;
''';
  }

  String _overpassBuildingQuery(LatLng center, double radiusMeters) {
    final lat = center.latitude;
    final lon = center.longitude;
    final r = radiusMeters.ceil();
    return '''
[out:json][timeout:25];
(
  way["building"](around:$r,$lat,$lon);
);
out geom;
''';
  }

  List<List<LatLng>> _parsePathWays(Map<String, dynamic> json) {
    final elements = json['elements'];
    if (elements is! List) {
      return [];
    }
    final out = <List<LatLng>>[];
    for (final e in elements) {
      if (e is! Map<String, dynamic>) {
        continue;
      }
      if (e['type'] != 'way') {
        continue;
      }
      final tags = e['tags'];
      if (tags is Map<String, dynamic>) {
        final access = tags['access']?.toString();
        if (access == 'private' || access == 'no') {
          continue;
        }
      }
      final geom = e['geometry'];
      if (geom is! List || geom.length < 2) {
        continue;
      }
      final pts = <LatLng>[];
      for (final n in geom) {
        if (n is Map<String, dynamic> && n['lat'] is num && n['lon'] is num) {
          pts.add(LatLng(
              (n['lat'] as num).toDouble(), (n['lon'] as num).toDouble()));
        }
      }
      if (pts.length >= 2) {
        out.add(pts);
      }
    }
    return out;
  }

  List<List<LatLng>> _parseBuildingPolygons(Map<String, dynamic> json) {
    final elements = json['elements'];
    if (elements is! List) {
      return [];
    }
    final out = <List<LatLng>>[];
    for (final e in elements) {
      if (e is! Map<String, dynamic>) {
        continue;
      }
      if (e['type'] != 'way') {
        continue;
      }
      final geom = e['geometry'];
      if (geom is! List || geom.length < 3) {
        continue;
      }
      final pts = <LatLng>[];
      for (final n in geom) {
        if (n is Map<String, dynamic> && n['lat'] is num && n['lon'] is num) {
          pts.add(LatLng(
              (n['lat'] as num).toDouble(), (n['lon'] as num).toDouble()));
        }
      }
      if (pts.length >= 3) {
        final first = pts.first;
        final last = pts.last;
        if (first.latitude != last.latitude ||
            first.longitude != last.longitude) {
          pts.add(first);
        }
        out.add(pts);
      }
    }
    return out;
  }

  Future<Map<String, dynamic>?> _postOverpass(String query) async {
    try {
      final res = await _client
          .post(
            Uri.parse(_overpassUrl),
            headers: const {
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: 'data=${Uri.encodeQueryComponent(query)}',
          )
          .timeout(const Duration(seconds: 35));
      if (res.statusCode != 200) {
        return null;
      }
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  List<List<LatLng>> _gridFallback(LatLng center, double radiusMeters) {
    final segments = <List<LatLng>>[];
    final latRad = center.latitude * math.pi / 180;
    final metersPerDegLat = 110574.0;
    final metersPerDegLon = 111320.0 * math.cos(latRad);
    final stepM = 45.0;
    final latStep = stepM / metersPerDegLat;
    final lonStep = stepM / metersPerDegLon;
    final n = math.max(1, (radiusMeters / stepM).ceil().clamp(1, 14));
    for (var i = -n; i <= n; i++) {
      for (var j = -n; j <= n; j++) {
        final p = LatLng(
          center.latitude + i * latStep,
          center.longitude + j * lonStep,
        );
        if (LocationUtils.distanceMeters(center, p) <= radiusMeters) {
          final q = LatLng(
            p.latitude + latStep * 0.02,
            p.longitude + lonStep * 0.02,
          );
          segments.add([p, q]);
        }
      }
    }
    return segments;
  }

  Future<List<List<LatLng>>> fetchNearbyPaths(
    LatLng center,
    double radiusMeters,
  ) async {
    final key = _cacheKey(center, radiusMeters);
    final hit = _pathCache[key];
    if (hit != null && DateTime.now().difference(hit.fetchedAt) < _cacheTtl) {
      _lastPathSegments = hit.segments;
      return List<List<LatLng>>.from(
        hit.segments.map((s) => List<LatLng>.from(s)),
      );
    }

    final q = _overpassHighwayQuery(center, radiusMeters);
    final json = await _postOverpass(q);
    List<List<LatLng>> segments;
    if (json == null) {
      segments = _gridFallback(center, radiusMeters);
    } else {
      segments = _parsePathWays(json);
      if (segments.isEmpty) {
        segments = _gridFallback(center, radiusMeters);
      }
    }

    _pathCache[key] = _CachedPaths(
      segments.map((s) => List<LatLng>.from(s)).toList(),
      DateTime.now(),
    );
    _lastPathSegments = _pathCache[key]!.segments;
    return List<List<LatLng>>.from(
      segments.map((s) => List<LatLng>.from(s)),
    );
  }

  Future<List<List<LatLng>>> _fetchBuildings(
    LatLng center,
    double radiusMeters,
  ) async {
    final key = '${_cacheKey(center, radiusMeters)}_bld';
    final hit = _buildingCache[key];
    if (hit != null && DateTime.now().difference(hit.fetchedAt) < _cacheTtl) {
      return hit.polygons.map((p) => List<LatLng>.from(p)).toList();
    }
    final json =
        await _postOverpass(_overpassBuildingQuery(center, radiusMeters));
    final polys =
        json == null ? <List<LatLng>>[] : _parseBuildingPolygons(json);
    _buildingCache[key] = _CachedBuildings(polys, DateTime.now());
    return polys;
  }

  bool _insideAnyBuilding(LatLng p, List<List<LatLng>> buildings) {
    for (final poly in buildings) {
      if (LocationUtils.pointInPolygon(p, poly)) {
        return true;
      }
    }
    return false;
  }

  Future<LatLng?> findValidSpawnPoint(
    LatLng currentPos,
    double bearing,
    double minDist,
    double maxDist,
  ) async {
    final searchR = math.max(maxDist * 2, 200.0);
    final paths = await fetchNearbyPaths(currentPos, searchR);
    final buildings = await _fetchBuildings(currentPos, searchR + maxDist + 50);

    const toleranceDeg = 60.0;
    const onPathMaxM = 12.0;

    for (var d = minDist; d <= maxDist; d += 15) {
      for (var a = -toleranceDeg; a <= toleranceDeg; a += 12) {
        final cand = LocationUtils.pointOnBearing(currentPos, bearing + a, d);
        if (!LocationUtils.isPointAhead(
          currentPos,
          bearing,
          cand,
          toleranceDeg,
        )) {
          continue;
        }
        var onPath = false;
        for (final seg in paths) {
          for (var i = 0; i < seg.length - 1; i++) {
            final dist = LocationUtils.distanceToSegmentMeters(
              seg[i],
              seg[i + 1],
              cand,
            );
            if (dist <= onPathMaxM) {
              onPath = true;
              break;
            }
          }
          if (onPath) {
            break;
          }
        }
        if (!onPath) {
          continue;
        }
        if (_insideAnyBuilding(cand, buildings)) {
          continue;
        }
        return cand;
      }
    }
    return null;
  }

  LatLng? snapToPath(LatLng point, {List<List<LatLng>>? pathSegments}) {
    final segments = pathSegments ?? _lastPathSegments;
    if (segments.isEmpty) {
      return null;
    }
    LatLng? best;
    var bestD = double.infinity;
    for (final seg in segments) {
      if (seg.length < 2) {
        continue;
      }
      for (var i = 0; i < seg.length - 1; i++) {
        final q =
            LocationUtils.closestPointOnSegment(seg[i], seg[i + 1], point);
        final d = LocationUtils.distanceMeters(point, q);
        if (d < bestD) {
          bestD = d;
          best = q;
        }
      }
    }
    return best;
  }
}
