import 'package:latlong2/latlong.dart';

Set<String> neighborhoodKeysFromRoute(List<LatLng> route) {
  final out = <String>{};
  for (final p in route) {
    final latKey = (p.latitude * 20).floor();
    final lngKey = (p.longitude * 20).floor();
    out.add('${latKey}_$lngKey');
  }
  return out;
}

Set<String> uniqueStreetCellKeysFromRoute(List<LatLng> route) {
  final cells = <String>{};
  for (final p in route) {
    cells.add('${(p.latitude * 100).floor()}_${(p.longitude * 100).floor()}');
  }
  return cells;
}
