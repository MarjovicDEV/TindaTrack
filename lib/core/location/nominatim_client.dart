import 'dart:convert';

import 'package:http/http.dart' as http;

class LocationSuggestion {
  const LocationSuggestion({required this.displayName, required this.lat, required this.lon});

  final String displayName;
  final double lat;
  final double lon;
}

/// Client for OpenStreetMap Nominatim search. Respect usage policy: cache, limit calls.
class NominatimClient {
  NominatimClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  static const _base = 'https://nominatim.openstreetmap.org/search';
  static const userAgent = 'TindaTrack/1.0';

  Future<List<LocationSuggestion>> search(String query, {int limit = 5}) async {
    final q = query.trim();
    if (q.isEmpty) return const [];

    final uri = Uri.parse(_base).replace(queryParameters: {
      'format': 'json',
      'q': q,
      'limit': '$limit',
    });

    final res = await _http.get(uri, headers: {'User-Agent': userAgent});
    if (res.statusCode != 200) {
      throw Exception('Nominatim HTTP ${res.statusCode}');
    }

    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return LocationSuggestion(
        displayName: m['display_name'] as String? ?? '',
        lat: double.tryParse('${m['lat']}') ?? 0,
        lon: double.tryParse('${m['lon']}') ?? 0,
      );
    }).toList();
  }

  void close() {
    _http.close();
  }
}
