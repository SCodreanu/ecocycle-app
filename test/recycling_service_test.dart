import 'dart:async';

import 'package:ecocycle/screens/map/map_screen.dart';
import 'package:ecocycle/services/recycling_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('GET preserves the existing Overpass query', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.host, 'ovp.dresel.systems');
      expect(request.url.path, '/api/interpreter');
      expect(
        request.url.queryParameters['data'],
        contains('nwr["amenity"="recycling"]'),
      );
      return http.Response(
        '{"elements":[{"id":1,"type":"node","lat":45.07,"lon":7.68}]}',
        200,
      );
    });
    addTearDown(client.close);
    expect(
      (await RecyclingService(client: client).fetchRecyclingPoints()).single.id,
      1,
    );
  });
  test('Invalid HTTP and partial Overpass responses fail instead of returning mock data', () async {
    for (final response in [
      http.Response('Unavailable', 503),
      http.Response('{"remark":"timeout","elements":[]}', 200),
      http.Response('not JSON', 200),
    ]) {
      final client = MockClient((_) async => response);
      await expectLater(
        RecyclingService(client: client).fetchRecyclingPoints(),
        throwsA(anything),
      );
      client.close();
    }
  });
  testWidgets('Map shows loading, error and retries to a genuine empty state', (
    tester,
  ) async {
    final response = Completer<http.Response>();
    var calls = 0;
    final client = MockClient((_) async {
      calls++;
      if (calls == 1) return response.future;
      return http.Response('{"elements":[]}', 200);
    });
    addTearDown(client.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapScreen(
            service: RecyclingService(client: client),
            onReport: (_) {},
          ),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    response.complete(http.Response('Unavailable', 503));
    await tester.pumpAndSettle();
    expect(
      find.text('Impossibile caricare i punti di riciclo.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Riprova'));
    await tester.pumpAndSettle();
    expect(
      find.text('Nessun punto di riciclo trovato nella zona di Torino.'),
      findsOneWidget,
    );
    expect(calls, 2);
  });
}
