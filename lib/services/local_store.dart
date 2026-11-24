import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

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
}
