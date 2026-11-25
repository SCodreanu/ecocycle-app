import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/recycling_point.dart';

class LocalStore {
  LocalStore(this.uid);
  final String uid;
  final _preferences = SharedPreferencesAsync();
  String _key(String name) => 'ecocycle.$uid.$name';

  Future<bool> onboardingCompleted() async =>
      await _preferences.getBool(_key('onboarding')) ?? false;

  Future<void> completeOnboarding(List<String> materials, String goal) async {
    await _preferences.setStringList(_key('materials'), materials);
    await _preferences.setString(_key('goal'), goal);
    await _preferences.setBool(_key('onboarding'), true);
  }

  Future<List<Map<String, dynamic>>> readRecords(String name) async {
    final raw = await _preferences.getString(_key(name));
    if (raw == null) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) throw const FormatException('Invalid local records');
    return decoded
        .map((record) => Map<String, dynamic>.from(record as Map))
        .toList();
  }

  Future<void> writeRecords(String name, List<Map<String, dynamic>> records) =>
      _preferences.setString(_key(name), jsonEncode(records));

  // Store a snapshot of each favorite so the profile can display it offline.
  Future<List<RecyclingPoint>> readFavorites() async {
    final records = await readRecords('favorites');
    final points = <String, RecyclingPoint>{};
    for (final record in records) {
      final point = RecyclingPoint.fromJson(record);
      if (point.isContainer) {
        points[point.key] = point;
      }
    }
    return points.values.toList();
  }

  Future<void> writeFavorites(List<RecyclingPoint> points) {
    final records = points.map((point) {
      final coordinates = <String, double>{
        'lat': point.latitude,
        'lon': point.longitude,
      };
      return <String, dynamic>{
        'id': point.id,
        'type': point.osmType,
        if (point.osmType == 'node') ...coordinates else 'center': coordinates,
        'tags': <String, String>{
          ...point.tags,
          if (point.name != null) 'name': point.name!,
          if (point.recyclingType != null)
            'recycling_type': point.recyclingType!,
        },
      };
    }).toList();
    return writeRecords('favorites', records);
  }
}
