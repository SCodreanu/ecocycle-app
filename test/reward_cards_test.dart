import 'package:ecocycle/services/xp_service.dart';
import 'package:ecocycle/widgets/rewards/reward_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> showCard(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(child: SizedBox(width: 320, child: child)),
      ),
    ),
  );
}

XpSummary sampleXp({bool missionCompleted = false}) => XpSummary(
  onboardingCompleted: true,
  reports: const [],
  activities: [
    {'date': '2026-11-23', 'material': 'Carta'},
    if (missionCompleted) ...[
      {'date': '2026-11-24', 'material': 'Carta'},
      {'date': '2026-11-25', 'material': 'Carta'},
    ],
  ],
  redemptions: const [],
  legacyRedemptions: const [],
);

RewardCard reward({
  int balance = 150,
  bool busy = false,
  bool redeemed = false,
  required VoidCallback onRedeem,
}) => RewardCard(
  name: 'Badge EcoCycle',
  cost: 150,
  icon: Icons.workspace_premium_outlined,
  redeemed: redeemed,
  balance: balance,
  busy: busy,
  onRedeem: onRedeem,
);

void main() {
  testWidgets('Balance card displays XP and level progress', (tester) async {
    await showCard(tester, XpBalanceCard(xp: sampleXp()));
    expect(find.text('150 XP'), findsOneWidget);
    expect(find.text('XP totali: 150 · Spesi: 0'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      closeTo(0.3, 0.0001),
    );
  });

  testWidgets('Mission card displays incomplete and completed progress', (
    tester,
  ) async {
    await showCard(tester, RewardMissionCard(xp: sampleXp()));
    expect(find.text('1/3 giorni'), findsOneWidget);
    await showCard(
      tester,
      RewardMissionCard(xp: sampleXp(missionCompleted: true)),
    );
    expect(find.text('Missione completata'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      1.0,
    );
  });

  testWidgets('Affordable reward invokes the supplied callback', (
    tester,
  ) async {
    var calls = 0;
    await showCard(tester, reward(onRedeem: () => calls++));
    await tester.tap(find.text('Riscatta'));
    await tester.pump();
    expect(calls, 1);
  });

  testWidgets('Insufficient balance or busy state disables redemption', (
    tester,
  ) async {
    await showCard(tester, reward(balance: 149, onRedeem: () {}));
    expect(find.text('XP insufficienti'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await showCard(tester, reward(busy: true, onRedeem: () {}));
    expect(find.text('Riscatta'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('Redeemed reward has no redemption button', (tester) async {
    await showCard(tester, reward(redeemed: true, onRedeem: () {}));
    expect(find.text('Riscattato'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });
}
