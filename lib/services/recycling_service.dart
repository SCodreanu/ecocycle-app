import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/recycling_point.dart';

class RecyclingService {
  RecyclingService({http.Client? client}) : _client = client;
  final http.Client? _client;
  static const _query = '''
[out:json][timeout:15];
nwr["amenity"="recycling"](45.00,7.58,45.14,7.77);
out center;
''';
  Future<List<RecyclingPoint>> fetchRecyclingPoints() async {
    final uri = Uri.https('ovp.dresel.systems', '/api/interpreter', {
      'data': _query,
    });
    final client = _client ?? http.Client();
    try {
      final response = await client
          .get(
            uri,
            headers: const {
              if (bool.fromEnvironment('dart.library.io'))
                'User-Agent':
                    'EcoCycle/1.0 (+https://github.com/SCodreanu/ecocycle-app)',
            },
          )
          .timeout(const Duration(seconds: 25));
      if (response.statusCode != 200)
        throw http.ClientException('Overpass HTTP ${response.statusCode}', uri);
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is! Map<String, dynamic> || data['remark'] != null)
        throw const FormatException('Invalid or incomplete Overpass response.');
      final elements = data['elements'];
      if (elements is! List)
        throw const FormatException('Missing Overpass elements.');
      return [
        for (final element in elements)
          RecyclingPoint.fromJson(element as Map<String, dynamic>),
      ];
    } finally {
      if (_client == null) client.close();
    }
  }
}
