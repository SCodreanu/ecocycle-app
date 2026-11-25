import 'dart:io';

import 'package:ecocycle/models/recycling_point.dart';
import 'package:ecocycle/services/local_store.dart';
import 'package:ecocycle/services/report_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStore implements LocalStore {
  @override
  final String uid = 'test-user';
  final _records = <String, List<Map<String, dynamic>>>{};
  bool failWrites = false;

  @override
  Future<List<Map<String, dynamic>>> readRecords(String name) async => [
    for (final record in _records[name] ?? <Map<String, dynamic>>[])
      Map<String, dynamic>.of(record),
  ];

  @override
  Future<void> writeRecords(
    String name,
    List<Map<String, dynamic>> records,
  ) async {
    if (failWrites) throw StateError('Simulated storage error');
    _records[name] = [for (final record in records) Map.of(record)];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _MemoryStore store;
  late ReportService service;
  late Directory temporary;
  final first = DateTime(2026, 11, 25, 9);
  final later = DateTime(2026, 11, 25, 12);
  const point = RecyclingPoint(
    id: 42,
    osmType: 'node',
    latitude: 45.07,
    longitude: 7.68,
    recyclingType: 'container',
  );

  setUp(() async {
    store = _MemoryStore();
    temporary = await Directory.systemTemp.createTemp('ecocycle-report-');
    service = ReportService(store, documentsDirectory: () async => temporary);
  });

  tearDown(() async {
    await temporary.delete(recursive: true);
  });

  test(
    'Saving reports preserves OSM data and rewards only once per day',
    () async {
      final saved = await service.save(
        category: 'Altro',
        description: '  Test report  ',
        point: point,
        now: first,
      );
      expect(saved.earnedXp, isTrue);
      final record = saved.records.single;
      expect(record['description'], 'Test report');
      expect(record['point'], point.key);
      expect(record['latitude'], point.latitude);
      expect(record['longitude'], point.longitude);
      expect(record['locationSource'], 'osm');
      final second = await service.save(
        category: 'Altro',
        description: 'Second report',
        now: later,
      );
      expect(second.earnedXp, isFalse);
      expect(await service.load(), hasLength(2));
    },
  );

  test('Deletion preserves the credited day without report contents', () async {
    final saved = await service.save(
      category: 'Altro',
      description: 'Private description',
      now: first,
    );
    final deleted = await service.delete(saved.records.single['id']);
    expect(deleted!.records, isEmpty);
    expect(await store.readRecords('report_xp_days'), [
      {'date': '2026-11-25'},
    ]);
    final repeated = await service.save(
      category: 'Altro',
      description: 'New report',
      now: later,
    );
    expect(repeated.earnedXp, isFalse);
    expect(await service.delete('missing'), isNull);
  });

  test('Photo is copied privately and removed with the report', () async {
    final original = await File('${temporary.path}/original.image')
        .writeAsBytes([1, 2, 3]);
    final saved = await service.save(
      category: 'Altro',
      description: 'Photo report',
      photoPath: original.path,
      now: first,
    );
    final record = saved.records.single;
    final copy = File(record['photo'] as String);
    expect(copy.path, isNot(original.path));
    expect(copy.parent.path, '${temporary.path}/reports/${store.uid}');
    expect(await copy.readAsBytes(), [1, 2, 3]);
    final deleted = await service.delete(record['id']);
    expect(deleted!.photoRemoved, isTrue);
    expect(await copy.exists(), isFalse);
    expect(await original.exists(), isTrue);
  });

  test('Failed report write removes the copied photo', () async {
    final original = await File('${temporary.path}/original.image')
        .writeAsBytes([1, 2, 3]);
    store.failWrites = true;
    await expectLater(
      service.save(
        category: 'Altro',
        description: 'Failed report',
        photoPath: original.path,
        now: first,
      ),
      throwsStateError,
    );
    final folder = Directory('${temporary.path}/reports/${store.uid}');
    expect(await folder.list().toList(), isEmpty);
    expect(await original.exists(), isTrue);
    expect(await service.load(), isEmpty);
  });
}
