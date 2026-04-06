import 'package:http/http.dart' as http;

Future<bool> mapTilesReachable() async {
  try {
    final r = await http
        .head(
          Uri.parse('https://tile.openstreetmap.org/0/0/0.png'),
        )
        .timeout(const Duration(seconds: 5));
    return r.statusCode == 200 || r.statusCode == 304;
  } catch (_) {
    return false;
  }
}
