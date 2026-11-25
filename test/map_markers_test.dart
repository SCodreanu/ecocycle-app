import 'package:ecocycle/models/recycling_point.dart';
import 'package:ecocycle/widgets/map/map_markers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const first = RecyclingPoint(
    id: 1,
    osmType: 'node',
    latitude: 45.073,
    longitude: 7.681,
  );
  const nearby = RecyclingPoint(
    id: 2,
    osmType: 'node',
    latitude: 45.074,
    longitude: 7.682,
  );
  const distant = RecyclingPoint(
    id: 3,
    osmType: 'node',
    latitude: 45.1,
    longitude: 7.7,
  );
  const points = [first, nearby, distant];

  test('Empty data produces no marker groups', () {
    expect(MapMarkers.groupPoints([], 12), isEmpty);
  });

  test('Nearby points share a grid cell at low zoom', () {
    expect(MapMarkers.groupPoints(points, 12), [
      [first, nearby],
      [distant],
    ]);
  });

  test('Street-level zoom keeps distinct OSM points separate', () {
    expect(MapMarkers.groupPoints(points, 16), [
      [first],
      [nearby],
      [distant],
    ]);
  });

  test('Grouping only includes currently filtered points', () {
    expect(MapMarkers.groupPoints([nearby, distant], 12), [
      [nearby],
      [distant],
    ]);
  });
}
