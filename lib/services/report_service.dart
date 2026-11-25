import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';

import '../models/recycling_point.dart';
import 'local_store.dart';
import 'xp_service.dart';

class ReportService {
  ReportService(this.store, {Future<Directory> Function()? documentsDirectory})
    : _documentsDirectory =
          documentsDirectory ?? getApplicationDocumentsDirectory;

  final LocalStore store;
  final Future<Directory> Function() _documentsDirectory;

  Future<List<Map<String, dynamic>>> load() => store.readRecords('reports');

  Future<Directory> _photoDirectory() async {
    final root = await _documentsDirectory();
    return Directory('${root.path}/reports/${Uri.encodeComponent(store.uid)}');
  }

  Future<({List<Map<String, dynamic>> records, bool earnedXp})> save({
    required String category,
    required String description,
    RecyclingPoint? point,
    Position? position,
    String? photoPath,
    DateTime? now,
  }) async {
    File? copied;
    var saved = false;
    try {
      final records = await load();
      final date = now ?? DateTime.now();
      final creditedDays = XpSummary.uniqueDays([
        ...records,
        ...await store.readRecords('report_xp_days'),
      ]);
      final earnedXp = !creditedDays.contains(XpSummary.dayKey(date));
      if (photoPath != null) {
        final directory = await _photoDirectory();
        await directory.create(recursive: true);
        // Preserve original image bytes in the user's private app directory.
        copied = await File(photoPath)
            .copy('${directory.path}/${date.microsecondsSinceEpoch}.image');
      }
      final record = <String, dynamic>{
        'id': date.microsecondsSinceEpoch.toString(),
        'date': date.toIso8601String(),
        'category': category,
        'description': description.trim(),
        'point': point?.key,
        'latitude': position?.latitude ?? point?.latitude,
        'longitude': position?.longitude ?? point?.longitude,
        'locationSource': position != null
            ? 'gps'
            : point != null
            ? 'osm'
            : null,
        'photo': copied?.path,
      };
      final next = [...records, record];
      await store.writeRecords('reports', next);
      saved = true;
      return (records: next, earnedXp: earnedXp);
    } finally {
      if (!saved && copied != null) {
        try {
          await copied.delete();
        } catch (_) {
          // Do not hide the original save failure.
        }
      }
    }
  }

  // Preserve only the credited day, not deleted report content.
  Future<({List<Map<String, dynamic>> records, bool photoRemoved})?> delete(
    Object? id,
  ) async {
    final records = await load();
    final matching = records.where((record) => record['id'] == id).toList();
    if (matching.isEmpty) return null;

    await XpService(store).preserveReportCredit(matching.first);
    final next = records.where((record) => record['id'] != id).toList();
    await store.writeRecords('reports', next);

    var photoRemoved = true;
    final photo = matching.first['photo'];
    if (photo is String && !next.any((record) => record['photo'] == photo)) {
      try {
        final folder = await _photoDirectory();
        final file = File(photo);
        if (file.parent.absolute.path == folder.absolute.path) {
          if (await file.exists()) await file.delete();
        } else {
          // Never delete a file outside the current user's report directory.
          photoRemoved = false;
        }
      } catch (_) {
        photoRemoved = false;
      }
    }
    return (records: next, photoRemoved: photoRemoved);
  }
}
