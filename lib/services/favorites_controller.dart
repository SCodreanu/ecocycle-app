import 'package:flutter/foundation.dart';

import '../models/recycling_point.dart';
import 'local_store.dart';

class FavoritesController extends ChangeNotifier {
  FavoritesController(this._store);

  final LocalStore _store;
  List<RecyclingPoint> _points = const [];
  bool _loading = false;
  bool _loadFailed = false;
  bool _loaded = false;
  bool _saving = false;
  bool _disposed = false;

  List<RecyclingPoint> get points => List.unmodifiable(_points);
  bool get loading => _loading;
  bool get loadFailed => _loadFailed;
  bool get ready => _loaded && !_loading && !_loadFailed;
  bool get saving => _saving;

  bool contains(RecyclingPoint point) =>
      _points.any((favorite) => favorite.key == point.key);

  Future<void> load() async {
    if (_disposed || _loading || _saving) return;
    _loading = true;
    _loadFailed = false;
    notifyListeners();
    try {
      final points = await _store.readFavorites();
      if (_disposed) return;
      _points = points;
      _loaded = true;
    } catch (error, stackTrace) {
      debugPrint('Favorites load error: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!_disposed) _loadFailed = true;
    } finally {
      if (!_disposed) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  // Update the shared state only after a successful local write.
  Future<bool> toggle(RecyclingPoint point) async {
    if (_disposed || !ready || _saving || !point.isContainer) return false;

    final next = List<RecyclingPoint>.of(_points);
    if (contains(point)) {
      next.removeWhere((favorite) => favorite.key == point.key);
    } else {
      next.add(point);
    }

    _saving = true;
    notifyListeners();
    try {
      await _store.writeFavorites(next);
      if (_disposed) return false;
      _points = next;
      return true;
    } catch (error, stackTrace) {
      debugPrint('Favorites save error: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    } finally {
      if (!_disposed) {
        _saving = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
