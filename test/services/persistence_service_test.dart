import 'package:flutter_test/flutter_test.dart';
import 'package:home_budget_app/services/persistence_service.dart';

// Builds a service whose writer returns each value from [results] in order,
// then returns true for any calls beyond the list.
PersistenceService _makeService(List<bool> results) {
  int i = 0;
  return PersistenceService(
    writer: (k, v) async => i < results.length ? results[i++] : true,
  );
}

void main() {
  // FR-TS5-1: write failure adds item to pending queue and marks it unsaved.
  group('FR-TS5-1 — write failure', () {
    test('failed write marks hasPending true', () async {
      final svc = PersistenceService(writer: (k, v) async => false);
      final result = await svc.write('key', 'value', affectedIds: {'item_1'});
      expect(result, isFalse);
      expect(svc.hasPending, isTrue);
    });

    test('failed write marks affected id as unsaved', () async {
      final svc = PersistenceService(writer: (k, v) async => false);
      await svc.write('key', 'value', affectedIds: {'item_1'});
      expect(svc.isUnsaved('item_1'), isTrue);
    });

    test('successful write leaves hasPending false and no unsaved marker', () async {
      final svc = PersistenceService(writer: (k, v) async => true);
      final result = await svc.write('key', 'value', affectedIds: {'item_1'});
      expect(result, isTrue);
      expect(svc.hasPending, isFalse);
      expect(svc.isUnsaved('item_1'), isFalse);
    });

    test('multiple affectedIds all marked unsaved on failure', () async {
      final svc = PersistenceService(writer: (k, v) async => false);
      await svc.write('key', 'v', affectedIds: {'a', 'b', 'c'});
      expect(svc.isUnsaved('a'), isTrue);
      expect(svc.isUnsaved('b'), isTrue);
      expect(svc.isUnsaved('c'), isTrue);
    });
  });

  // FR-TS5-2: next write attempt flushes pending queue before writing new item.
  group('FR-TS5-2 — flush before next write', () {
    test('next write flushes pending item before writing the new item', () async {
      final callKeys = <String>[];
      int call = 0;
      final svc = PersistenceService(writer: (k, v) async {
        callKeys.add(k);
        call++;
        return call > 1; // call 1 fails; calls 2+ succeed
      });

      await svc.write('key_a', 'val_a', affectedIds: {'a_1'});
      await svc.write('key_b', 'val_b', affectedIds: {'b_1'});

      // flush of key_a (call 2) must precede write of key_b (call 3)
      expect(callKeys, ['key_a', 'key_a', 'key_b']);
    });
  });

  // FR-TS5-3: successful flush removes items from queue and clears unsaved markers.
  group('FR-TS5-3 — successful flush clears state', () {
    test('flush success removes pending item', () async {
      // call 1: new write fails; call 2: flush succeeds; call 3: next write succeeds
      final svc = _makeService([false, true, true]);
      await svc.write('key', 'v1', affectedIds: {'item_1'});
      expect(svc.hasPending, isTrue);

      await svc.write('key2', 'v2');
      expect(svc.hasPending, isFalse);
    });

    test('flush success clears unsaved marker', () async {
      final svc = _makeService([false, true, true]);
      await svc.write('key', 'v1', affectedIds: {'item_1'});
      expect(svc.isUnsaved('item_1'), isTrue);

      await svc.write('key2', 'v2');
      expect(svc.isUnsaved('item_1'), isFalse);
    });

    test('retryPending clears pending and marker on success', () async {
      var fail = true;
      final svc = PersistenceService(writer: (k, v) async => !fail);

      await svc.write('key', 'v', affectedIds: {'item_1'});
      expect(svc.isUnsaved('item_1'), isTrue);

      fail = false;
      final ok = await svc.retryPending();
      expect(ok, isTrue);
      expect(svc.hasPending, isFalse);
      expect(svc.isUnsaved('item_1'), isFalse);
    });
  });

  // FR-TS5-4: failed flush keeps items in queue with markers set.
  group('FR-TS5-4 — failed flush keeps state', () {
    test('failed flush leaves pending item in queue', () async {
      final svc = PersistenceService(writer: (k, v) async => false);
      await svc.write('key', 'v', affectedIds: {'item_1'});
      await svc.write('key2', 'v2', affectedIds: {'item_2'});

      expect(svc.hasPending, isTrue);
      expect(svc.isUnsaved('item_1'), isTrue);
    });

    test('retryPending returns false when flush still fails', () async {
      final svc = PersistenceService(writer: (k, v) async => false);
      await svc.write('key', 'v', affectedIds: {'item_1'});

      final ok = await svc.retryPending();
      expect(ok, isFalse);
      expect(svc.hasPending, isTrue);
      expect(svc.isUnsaved('item_1'), isTrue);
    });
  });

  // FR-TS5-5: multiple queued items are all cleared on successful flush.
  group('FR-TS5-5 — multiple pending items', () {
    test('successful flush clears all pending items and their markers', () async {
      var fail = true;
      final svc = PersistenceService(writer: (k, v) async => !fail);

      // Both writes (and the intermediate flush attempt) fail while fail=true.
      await svc.write('key_a', 'val_a', affectedIds: {'a_1'});
      await svc.write('key_b', 'val_b', affectedIds: {'b_1'});
      expect(svc.isUnsaved('a_1'), isTrue);
      expect(svc.isUnsaved('b_1'), isTrue);

      fail = false;
      final ok = await svc.retryPending();
      expect(ok, isTrue);
      expect(svc.isUnsaved('a_1'), isFalse);
      expect(svc.isUnsaved('b_1'), isFalse);
      expect(svc.hasPending, isFalse);
    });

    test('partial flush: succeeded items cleared, failed items kept', () async {
      // key_a flush succeeds (call 2), key_b flush fails (call 3)
      int call = 0;
      final svc = PersistenceService(writer: (k, v) async {
        call++;
        // call 1: key_a initial write → fail
        // call 2: key_a flush → succeed
        // call 3: key_b initial write → fail (triggers flush of key_a first)
        //   actually: flush(key_a) = call 2 succeed → then write(key_b) = call 3 fail
        // call 4: retryPending → key_b retry fails
        if (call == 2) return true; // key_a flush succeeds
        return false;               // everything else fails
      });

      await svc.write('key_a', 'val_a', affectedIds: {'a_1'});
      // key_a in pending

      await svc.write('key_b', 'val_b', affectedIds: {'b_1'});
      // flush: key_a (call 2 → succeed) cleared; write key_b (call 3 → fail) pending

      expect(svc.isUnsaved('a_1'), isFalse); // flushed successfully
      expect(svc.isUnsaved('b_1'), isTrue);  // still failed
      expect(svc.hasPending, isTrue);
    });
  });
}
