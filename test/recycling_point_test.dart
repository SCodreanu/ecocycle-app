import 'package:ecocycle/models/bin_status.dart';
import 'package:ecocycle/models/recycling_point.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final data = {
    'type': 'node',
    'id': 42,
    'lat': 45.07,
    'lon': 7.68,
    'tags': {
      'amenity': 'recycling',
      'recycling_type': 'container',
      'recycling:glass': 'yes',
      'recycling:plastic': 'no',
      'addr:street': 'Via di esempio',
      'addr:housenumber': '1',
    },
  };
  test('Parses node coordinates and real material tags', () {
    final point = RecyclingPoint.fromJson(data);
    expect(point.key, 'node/42');
    expect(point.latitude, 45.07);
    expect(point.isContainer, isTrue);
    expect(point.materials, ['Vetro']);
    expect(point.address, 'Via di esempio 1');
  });
  test('Parses a way centre and does not invent material or address', () {
    final point = RecyclingPoint.fromJson({
      'type': 'way',
      'id': 42,
      'center': {'lat': 45, 'lon': 7},
      'tags': {'recycling_type': 'centre'},
    });
    expect(point.key, 'way/42');
    expect(point.isContainer, isFalse);
    expect(point.title, 'Centro di raccolta');
    expect(point.address, isNull);
    expect(point.materials, isEmpty);
  });
  test('Rejects malformed coordinates', () {
    expect(
      () => RecyclingPoint.fromJson({
        'type': 'node',
        'id': 1,
        'lat': 95,
        'lon': 7,
      }),
      throwsFormatException,
    );
    expect(
      () => RecyclingPoint.fromJson({'type': 'way', 'id': 1}),
      throwsFormatException,
    );
  });
  test('Telemetry is stable for the same OSM identity', () {
    final a = BinStatusData.forPoint(RecyclingPoint.fromJson(data));
    final b = BinStatusData.forPoint(RecyclingPoint.fromJson(data));
    expect(a.fillLevel, b.fillLevel);
    expect(a.status, b.status);
    expect(a.weight, b.weight);
    expect(a.gasReading, b.gasReading);
    expect(a.fillLevel, inInclusiveRange(0, 100));
  });
  test('Thresholds and operational priority are consistent', () {
    expect(BinStatus.fromFill(49), BinStatus.normal);
    expect(BinStatus.fromFill(50), BinStatus.nearlyFull);
    expect(BinStatus.fromFill(79), BinStatus.nearlyFull);
    expect(BinStatus.fromFill(80), BinStatus.full);
    expect(BinStatus.fromFill(100, maintenance: true), BinStatus.maintenance);
    expect(
      BinStatus.fromFill(100, maintenance: true, unavailable: true),
      BinStatus.unavailable,
    );
  });
}
