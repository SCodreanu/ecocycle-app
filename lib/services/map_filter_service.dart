import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/bin_status.dart';
import '../models/recycling_point.dart';

class MapFilterService {
  static List<String> availableMaterials(List<RecyclingPoint> points) {
    return points.expand((point) => point.materials).toSet().toList()..sort();
  }

  static List<RecyclingPoint> filter(
    List<RecyclingPoint> points, {
    String query = '',
    String material = '',
    BinStatus? status,
    bool onlyFavorites = false,
    bool Function(RecyclingPoint)? isFavorite,
    LatLng? location,
  }) {
    final normalizedQuery = query.trim().toLowerCase();

    final filtered = points.where((point) {
      if (onlyFavorites && isFavorite?.call(point) != true) {
        return false;
      }

      if (material.isNotEmpty && !point.materials.contains(material)) {
        return false;
      }

      if (status != null &&
          (!point.isContainer ||
              BinStatusData.forPoint(point).status != status)) {
        return false;
      }

      final searchableText =
          '${point.title} ${point.address ?? ''} '
          '${point.key} ${point.materials.join(' ')}';

      return normalizedQuery.isEmpty ||
          searchableText.toLowerCase().contains(normalizedQuery);
    }).toList();

    if (location != null) {
      filtered.sort(
        (a, b) =>
            _distanceFrom(location, a).compareTo(_distanceFrom(location, b)),
      );
    }

    return filtered;
  }

  static double _distanceFrom(LatLng location, RecyclingPoint point) {
    return Geolocator.distanceBetween(
      location.latitude,
      location.longitude,
      point.latitude,
      point.longitude,
    );
  }

  static double _distanceBetween(RecyclingPoint first, RecyclingPoint second) {
    return _distanceFrom(LatLng(first.latitude, first.longitude), second);
  }

  static List<RecyclingPoint> findAlternatives(
    RecyclingPoint selected,
    List<RecyclingPoint> allPoints,
  ) {
    if (!selected.isContainer || selected.materials.isEmpty) {
      return [];
    }

    final knownMaterials = selected.materialCodes
        .where(RecyclingPoint.materialNames.containsKey)
        .map((code) => RecyclingPoint.materialNames[code]!)
        .toSet();

    if (knownMaterials.isEmpty) return [];

    final alternatives = allPoints.where((point) {
      if (point.key == selected.key || !point.isContainer) {
        return false;
      }

      if (!point.materials.any(knownMaterials.contains)) {
        return false;
      }

      final status = BinStatusData.forPoint(point).status;

      final isAvailable =
          status == BinStatus.normal || status == BinStatus.nearlyFull;

      return isAvailable && _distanceBetween(selected, point) <= 3000;
    }).toList();

    alternatives.sort(
      (a, b) => _distanceBetween(
        selected,
        a,
      ).compareTo(_distanceBetween(selected, b)),
    );

    return alternatives.take(3).toList();
  }
}
