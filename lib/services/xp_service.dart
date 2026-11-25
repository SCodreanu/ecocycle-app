import 'local_store.dart';

class XpSummary {
  XpSummary({
    required this.onboardingCompleted,
    required List<Map<String, dynamic>> reports,
    required this.activities,
    required this.redemptions,
    required this.legacyRedemptions,
  }) : reportDays = uniqueDays(reports);

  final bool onboardingCompleted;
  final List<Map<String, dynamic>> activities;
  final List<Map<String, dynamic>> redemptions;
  final List<Map<String, dynamic>> legacyRedemptions;
  final Set<String> reportDays;

  static Set<String> uniqueDays(List<Map<String, dynamic>> records) => {
    for (final record in records)
      if (record['date'] is String &&
          DateTime.tryParse(record['date'] as String) != null)
        (record['date'] as String).split('T').first,
  };

  static String dayKey(DateTime date) =>
      date.toIso8601String().split('T').first;

  Set<String> get activityDays => uniqueDays(activities);
  int get recyclingCount => activityDays.length;
  int get recyclingXp =>
      recyclingCount == 0 ? 0 : 50 + (recyclingCount - 1) * 20;
  bool get missionCompleted => recyclingCount >= 3;
  int get totalXp =>
      (onboardingCompleted ? 100 : 0) +
      recyclingXp +
      reportDays.length * 50 +
      (missionCompleted ? 100 : 0);
  int get spentXp =>
      redemptions.fold<int>(0, (sum, r) => sum + (r['cost'] as int));
  int get balance => totalXp >= spentXp ? totalXp - spentXp : 0;
  int get level => totalXp ~/ 500 + 1;
  int get nextLevelXp => level * 500;
  double get levelProgress => (totalXp % 500) / 500;
  bool recycledOn(DateTime date) => activityDays.contains(dayKey(date));
  bool redeemed(String id) => redemptions.any((r) => r['id'] == id);
}

class XpService {
  XpService(this.store);
  final LocalStore store;

  Future<XpSummary> load() async => XpSummary(
    onboardingCompleted: await store.onboardingCompleted(),
    reports: [
      ...await store.readRecords('reports'),
      ...await store.readRecords('report_xp_days'),
    ],
    activities: await store.readRecords('recycling_activities'),
    redemptions: await store.readRecords('rewards_v2'),
    legacyRedemptions: await store.readRecords('rewards'),
  );

  // Retain only the earned calendar day, not the deleted report content.
  Future<void> preserveReportCredit(Map<String, dynamic> report) async {
    final days = XpSummary.uniqueDays([report]);
    if (days.isEmpty) return;
    final existing = await store.readRecords('report_xp_days');
    final next = {...XpSummary.uniqueDays(existing), ...days};
    await store.writeRecords('report_xp_days', [
      for (final day in next) {'date': day},
    ]);
  }

  Future<XpSummary> recordRecycling(String material) async {
    final current = await load();
    final now = DateTime.now();
    if (current.recycledOn(now)) return current;
    await store.writeRecords('recycling_activities', [
      ...current.activities,
      {'date': now.toIso8601String(), 'material': material},
    ]);
    return load();
  }

  Future<XpSummary> redeem(String id, String name, int cost) async {
    final current = await load();
    if (cost <= 0 || current.balance < cost || current.redeemed(id)) {
      throw StateError('Reward unavailable');
    }
    await store.writeRecords('rewards_v2', [
      ...current.redemptions,
      {
        'id': id,
        'name': name,
        'cost': cost,
        'date': DateTime.now().toIso8601String(),
      },
    ]);
    return load();
  }
}
