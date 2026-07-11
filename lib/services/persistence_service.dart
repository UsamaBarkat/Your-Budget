import 'package:shared_preferences/shared_preferences.dart';

class _PendingWrite {
  final String key;
  final String value;
  final Set<String> affectedIds;

  _PendingWrite({
    required this.key,
    required this.value,
    required this.affectedIds,
  });
}

class PersistenceService {
  final Future<bool> Function(String key, String value) _writer;
  final _pending = <String, _PendingWrite>{};
  final _unsavedIds = <String>{};

  PersistenceService({Future<bool> Function(String key, String value)? writer})
      : _writer = writer ?? _defaultWriter;

  static Future<bool> _defaultWriter(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(key, value);
  }

  bool get hasPending => _pending.isNotEmpty;

  bool isUnsaved(String id) => _unsavedIds.contains(id);

  // [affectedIds]: IDs whose unsaved markers clear on success or set on failure.
  Future<bool> write(
    String key,
    String value, {
    Set<String> affectedIds = const <String>{},
  }) async {
    if (_pending.isNotEmpty) await _flushAll();

    final success = await _writer(key, value);
    if (success) {
      final removed = _pending.remove(key);
      if (removed != null) _unsavedIds.removeAll(removed.affectedIds);
    } else {
      final existing = _pending[key];
      _pending[key] = _PendingWrite(
        key: key,
        value: value,
        affectedIds: {...?existing?.affectedIds, ...affectedIds},
      );
      _unsavedIds.addAll(affectedIds);
    }
    return success;
  }

  /// Re-attempts all pending writes. Returns true if the queue is now empty.
  Future<bool> retryPending() async {
    await _flushAll();
    return _pending.isEmpty;
  }

  Future<void> _flushAll() async {
    for (final key in List<String>.from(_pending.keys)) {
      final pending = _pending[key]!;
      final success = await _writer(pending.key, pending.value);
      if (success) {
        _pending.remove(key);
        _unsavedIds.removeAll(pending.affectedIds);
      }
    }
  }
}
