import 'package:ecocycle/models/recycling_point.dart';
import 'package:ecocycle/services/map_filter_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const paper = RecyclingPoint(
    id: 1,
    osmType: 'node',
    latitude: 45.07,
    longitude: 7.68,
    recyclingType: 'container',
    tags: {'recycling:paper': 'yes'},
  );

  const glass = RecyclingPoint(
    id: 2,
    osmType: 'node',
    latitude: 45.08,
    longitude: 7.69,
    recyclingType: 'container',
    tags: {'recycling:glass': 'yes'},
  );

  const points = [paper, glass];

  test('Available materials are unique and sorted', () {
    expect(MapFilterService.availableMaterials(points), ['Carta', 'Vetro']);
  });

  test('Search and material filters can be combined', () {
    expect(MapFilterService.filter(points, query: 'CARTA', material: 'Carta'), [
      paper,
    ]);

    expect(
      MapFilterService.filter(points, query: 'Carta', material: 'Vetro'),
      isEmpty,
    );
  });

  test('Favorites filter returns only selected points', () {
    expect(
      MapFilterService.filter(
        points,
        onlyFavorites: true,
        isFavorite: (point) => point.key == paper.key,
      ),
      [paper],
    );
  });
}
