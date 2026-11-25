import 'package:ecocycle/services/auth_service.dart';
import 'package:ecocycle/theme/app_theme.dart';
import 'package:ecocycle/widgets/brand_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Email validation rejects missing and malformed values', () {
    expect(AuthService.validateEmail(null), isNotNull);
    expect(AuthService.validateEmail('example'), isNotNull);
    expect(AuthService.validateEmail('user@example.com'), isNull);
  });
  testWidgets(
    'Brand header displays the original logo and copy without Firebase',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: BrandHeader(title: 'EcoCycle', subtitle: 'Demo'),
          ),
        ),
      );
      expect(find.text('EcoCycle'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Brand header also renders in dark mode', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: BrandHeader(title: 'EcoCycle', subtitle: 'Demo'),
        ),
      ),
    );
    expect(find.text('EcoCycle'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(BrandHeader))).brightness,
      Brightness.dark,
    );
    expect(tester.takeException(), isNull);
  });
}
