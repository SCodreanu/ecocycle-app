import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/bin_status.dart';
import '../../models/recycling_point.dart';

class MapMarkers {
  // A geographic grid groups nearby points at low zoom. At street level each
  // point is rendered individually. Counts refer to the currently filtered data.
  static List<List<RecyclingPoint>> groupPoints(
    List<RecyclingPoint> points,
    int zoomBucket,
  ) {
    final cellSize = .018 / math.pow(2, zoomBucket - 12);
    final groups = <String, List<RecyclingPoint>>{};
    for (final point in points) {
      final key = zoomBucket >= 16
          ? point.key
          : '${(point.latitude / cellSize).floor()}:${(point.longitude / cellSize).floor()}';
      groups.putIfAbsent(key, () => []).add(point);
    }
    return groups.values.toList();
  }

  static List<Marker> build({
    required List<RecyclingPoint> points,
    required int zoomBucket,
    required ColorScheme colors,
    required ValueChanged<RecyclingPoint> onPointTap,
    required ValueChanged<LatLng> onClusterTap,
  }) {
    return [
      for (final group in groupPoints(points, zoomBucket))
        if (group.length > 1)
          _clusterMarker(group, colors, onClusterTap)
        else
          _singleMarker(group.first, colors, onPointTap),
    ];
  }

  static Marker _clusterMarker(
    List<RecyclingPoint> points,
    ColorScheme colors,
    ValueChanged<LatLng> onClusterTap,
  ) {
    final center = LatLng(
      points.fold<double>(0, (sum, point) => sum + point.latitude) /
          points.length,
      points.fold<double>(0, (sum, point) => sum + point.longitude) /
          points.length,
    );
    return Marker(
      point: center,
      width: 48,
      height: 48,
      child: Tooltip(
        message: '${points.length} punti di raccolta',
        child: GestureDetector(
          onTap: () => onClusterTap(center),
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primary,
                border: Border.all(color: colors.surface, width: 3),
              ),
              child: Text(
                '${points.length}',
                style: TextStyle(
                  color: colors.onPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Marker _singleMarker(
    RecyclingPoint point,
    ColorScheme colors,
    ValueChanged<RecyclingPoint> onPointTap,
  ) {
    final demo = BinStatusData.forPoint(point);
    final color = point.isContainer
        ? demo.status.color
        : const Color(0xff176b66);
    return Marker(
      point: LatLng(point.latitude, point.longitude),
      width: 44,
      height: 44,
      child: GestureDetector(
        onTap: () => onPointTap(point),
        child: Tooltip(
          message: point.title,
          child: Center(
            child: Container(
              width: 31,
              height: 31,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                point.isContainer ? demo.status.icon : Icons.recycling,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
