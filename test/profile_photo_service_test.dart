import 'dart:io';

import 'package:ecocycle/services/profile_photo_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;
  late ProfilePhotoService service;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('ecocycle_avatar_');
    service = ProfilePhotoService(
      'user-a',
      documentsDirectory: () async => root,
    );
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  test('Missing avatar returns null; removal is safe', () async {
    expect(await service.load(), isNull);
    final removed = await service.remove();
    expect(await removed.exists(), isFalse);
  });

  test('Save and replace preserve the existing avatar path', () async {
    final source = await File('${root.path}/source.image').writeAsBytes([1, 2]);
    final first = await service.save(source.path);
    expect(first.path, '${root.path}/profile_photos/user-a/avatar.image');
    expect(await (await service.load())!.readAsBytes(), [1, 2]);

    await source.writeAsBytes([3, 4]);
    final second = await service.save(source.path);
    expect(second.path, first.path);
    expect(await (await service.load())!.readAsBytes(), [3, 4]);
    expect(await File('${first.path}.tmp').exists(), isFalse);
  });

  test(
    'Photos are isolated by user and removal affects only that user',
    () async {
      final other = ProfilePhotoService(
        'user-b',
        documentsDirectory: () async => root,
      );
      final source = await File('${root.path}/source.image').writeAsBytes([5]);
      await service.save(source.path);
      expect(await other.load(), isNull);
      await other.save(source.path);

      await service.remove();
      expect(await service.load(), isNull);
      expect(await (await other.load())!.readAsBytes(), [5]);
    },
  );

  test('Failed copy preserves the previous avatar', () async {
    final source = await File('${root.path}/source.image').writeAsBytes([7]);
    final saved = await service.save(source.path);
    await expectLater(
      service.save('${root.path}/missing.image'),
      throwsA(isA<FileSystemException>()),
    );
    expect(await (await service.load())!.readAsBytes(), [7]);
    expect(await File('${saved.path}.tmp').exists(), isFalse);
  });
}
