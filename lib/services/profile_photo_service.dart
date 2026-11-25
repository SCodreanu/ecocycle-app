import 'dart:io';

import 'package:path_provider/path_provider.dart';

class ProfilePhotoService {
  ProfilePhotoService(
    this.uid, {
    Future<Directory> Function()? documentsDirectory,
  }) : _documentsDirectory =
           documentsDirectory ?? getApplicationDocumentsDirectory;

  final String uid;
  final Future<Directory> Function() _documentsDirectory;

  // Keep the existing per-user storage path so saved photos are preserved.
  Future<File> _photoFile() async {
    final root = await _documentsDirectory();
    final folder = Uri.encodeComponent(uid);
    return File('${root.path}/profile_photos/$folder/avatar.image');
  }

  Future<File?> load() async {
    final file = await _photoFile();
    return await file.exists() ? file : null;
  }

  Future<File> save(String sourcePath) async {
    final target = await _photoFile();
    await target.parent.create(recursive: true);
    final temporary = File('${target.path}.tmp');

    try {
      // Copy first, so a failed copy does not replace the existing avatar.
      await File(sourcePath).copy(temporary.path);
      await temporary.rename(target.path);
      return target;
    } finally {
      try {
        if (await temporary.exists()) {
          await temporary.delete();
        }
      } catch (_) {
        // A temporary file can be overwritten on the next selection.
      }
    }
  }

  // Return the file so the UI can invalidate its image cache.
  Future<File> remove() async {
    final file = await _photoFile();
    if (await file.exists()) {
      await file.delete();
    }
    return file;
  }
}
