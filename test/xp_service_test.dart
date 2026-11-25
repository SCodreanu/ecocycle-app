import 'package:ecocycle/services/xp_service.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> activity(String date) => {
  'date': date,
  'material': 'Vetro',
};
Map<String, dynamic> report(String date) => {'date': date};

XpSummary summary({
  bool onboarding = true,
  List<Map<String, dynamic>> activities = const [],
  List<Map<String, dynamic>> reports = const [],
  List<Map<String, dynamic>> redemptions = const [],
  List<Map<String, dynamic>> legacy = const [],
}) => XpSummary(
  onboardingCompleted: onboarding,
  reports: reports,
  activities: activities,
  redemptions: redemptions,
  legacyRedemptions: legacy,
);

void main() {
  test('New account earns onboarding bonus only once', () {
    expect(summary(onboarding: false).totalXp, 0);
    expect(summary().totalXp, 100);
    expect(summary().level, 1);
  });
  test('Recycling and reports reward distinct calendar days', () {
    final xp = summary(
      activities: [
        activity('2026-11-25T09:00:00'),
        activity('2026-11-25T12:00:00'),
      ],
      reports: [report('2026-11-25T13:00:00'), report('2026-11-25T15:00:00')],
    );
    expect(xp.recyclingCount, 1);
    expect(xp.reportDays.length, 1);
    expect(xp.totalXp, 200);
    expect(xp.recycledOn(DateTime(2026, 11, 25)), isTrue);
  });
  test('Third distinct recycling day unlocks mission automatically', () {
    final xp = summary(
      activities: [
        activity('2026-11-23'),
        activity('2026-11-24'),
        activity('2026-11-25'),
      ],
    );
    expect(xp.recyclingXp, 90);
    expect(xp.missionCompleted, isTrue);
    expect(xp.totalXp, 290);
    final next = summary(
      activities: [...xp.activities, activity('2026-11-26')],
    );
    expect(next.totalXp, 310);
  });
  test('Redemption reduces spendable balance but not level', () {
    final reports = [
      for (var day = 1; day <= 8; day++) report('2026-11-0$day'),
    ];
    final before = summary(reports: reports);
    final after = summary(
      reports: reports,
      redemptions: [
        {'id': 'badge', 'cost': 150},
      ],
    );
    expect(before.totalXp, 500);
    expect(after.totalXp, before.totalXp);
    expect(after.level, 2);
    expect(after.balance, 350);
    expect(after.redeemed('badge'), isTrue);
    expect(after.levelProgress, 0);
  });
  test('Legacy demo redemptions do not consume new XP', () {
    final xp = summary(
      legacy: [
        {'id': 'tree', 'cost': 1500},
      ],
    );
    expect(xp.balance, 100);
    expect(xp.legacyRedemptions.length, 1);
    expect(xp.redeemed('tree'), isFalse);
  });
}
