import 'package:ecocycle/theme/app_theme.dart';
import 'package:ecocycle/widgets/eco_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
    testWidgets('Metrics render in ${theme.brightness.name}', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: EcoMetricGrid(
                  children: [
                    EcoMetric(
                      icon: Icons.thermostat,
                      label: 'Temperatura',
                      value: '22.4 °C',
                    ),
                    EcoMetric(
                      icon: Icons.inventory_2_outlined,
                      label: 'Capacità totale',
                      value: '660 L',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('22.4 °C'), findsOneWidget);
      expect(find.text('660 L'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
