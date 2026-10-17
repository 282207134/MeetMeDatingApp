import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetme/src/store.dart';
import 'support.dart';

void main() {
  late MemoryStorage storage;
  late AppStore store;
  setUp(() {
    storage = MemoryStorage();
    store = AppStore(storage, replyDelay: const Duration(milliseconds: 10));
  });
  tearDown(() => store.dispose());

  test('matching is unique; pass, undo and filters change discovery', () async {
    final cayla = people.first;
    store.pass(cayla);
    expect(store.candidates.first.id, 'sofia');
    store.undoPass();
    expect(store.candidates.first.id, 'cayla');
    expect(store.like(cayla), isTrue);
    expect(store.like(cayla), isFalse);
    expect(store.matchIds.where((id) => id == 'cayla'), hasLength(1));
    expect(store.messages['cayla'], hasLength(1));
    store.saveFilters(Filters(distance: 1));
    expect(store.candidates, isEmpty);
  });

  test(
    'profile, preferences, connections and messages survive reloading',
    () async {
      store.startDemo();
      store.saveProfile(
        store.profile.copy()
          ..name = 'Taylor'
          ..bio = 'A saved introduction',
      );
      store.favorite(people.first);
      store.like(people.first);
      store.saveFilters(Filters(minAge: 25, maxAge: 35, distance: 12));
      store.setNotifications(false);
      final emma = store.person('emma');
      store.readChat(emma);
      store.send('Coffee tomorrow?', emma);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await store.flush();
      final restored = await AppStore.load(storage);
      addTearDown(restored.dispose);
      expect(restored.profile.name, 'Taylor');
      expect(restored.profile.bio, 'A saved introduction');
      expect(restored.notifications, isFalse);
      expect(restored.filters.distance, 12);
      expect(restored.matchIds, contains('cayla'));
      expect(restored.favorites, contains('cayla'));
      expect(
        restored.messages['emma']!.last.text,
        contains('Coffee sounds lovely'),
      );
      expect(restored.unread['emma'], 0);
    },
  );

  test(
    'unmatching and blocking prevent delayed replies from returning',
    () async {
      final emma = store.person('emma');
      store.send('Hello', emma);
      store.block(emma);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(store.messages.containsKey('emma'), isFalse);
      expect(store.matchIds, isNot(contains('emma')));
      expect(store.candidates.map((p) => p.id), isNot(contains('emma')));
      store.unblock(emma);
      expect(store.blocked, isEmpty);
    },
  );

  test(
    'empty messages are ignored and unseen replies increment unread',
    () async {
      final emma = store.person('emma');
      store.readChat(emma);
      store.send('   ', emma);
      expect(store.messages['emma'], hasLength(3));
      store.send('Hello', emma);
      store.leaveChat(emma);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(store.messages['emma'], hasLength(5));
      expect(store.unread['emma'], 1);
    },
  );

  test(
    'local registration stores no password; reset cancels old replies',
    () async {
      store.signIn(name: ' Jordan ', email: 'jordan@example.com', create: true);
      expect(store.profileComplete, isFalse);
      expect(store.profile.name, 'Jordan');
      await store.flush();
      expect(jsonDecode(storage.value!).containsKey('password'), isFalse);
      store.send('Coffee?', store.person('emma'));
      store.reset();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(store.signedIn, isFalse);
      expect(store.messages['emma'], hasLength(3));
      expect(store.profile.name, 'Alex');
    },
  );

  test('corrupt saved data recovers to a usable fresh demo', () async {
    storage.value = '{invalid data';
    final restored = await AppStore.load(storage);
    addTearDown(restored.dispose);
    expect(restored.signedIn, isFalse);
    expect(restored.storageError, isNotNull);
    restored.startDemo();
    await restored.flush();
    expect(restored.storageError, isNull);
    expect(jsonDecode(storage.value!)['signedIn'], isTrue);
  });
}
