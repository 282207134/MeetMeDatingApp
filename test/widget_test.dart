import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetme/src/app.dart';
import 'package:meetme/src/store.dart';
import 'support.dart';

void main() {
  late AppStore store;
  setUp(
    () => store = AppStore(
      MemoryStorage(),
      replyDelay: const Duration(milliseconds: 50),
    ),
  );
  tearDown(() => store.dispose());
  Future<void> boot(WidgetTester tester, {bool demo = false}) async {
    await tester.binding.setSurfaceSize(const Size(402, 874));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    if (demo) store.startDemo();
    await tester.pumpWidget(MeetMeApp(store: store));
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Key key) async {
    final finder = find.byKey(key);
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        240,
        scrollable: find.byType(Scrollable).hitTestable().last,
      );
    }
    await Scrollable.ensureVisible(
      tester.element(finder),
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
    );
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'registration validates inputs and completes three profile steps',
    (tester) async {
      await boot(tester);
      await tap(tester, const Key('createAccount'));
      await tap(tester, const Key('authSubmit'));
      expect(find.text('Enter your name'), findsOneWidget);
      expect(find.text('Enter a valid email'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('authName')), 'Jordan');
      await tester.enterText(
        find.byKey(const Key('authEmail')),
        'jordan@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('authPassword')),
        'sample123',
      );
      await tap(tester, const Key('adultConfirm'));
      await tap(tester, const Key('authSubmit'));
      expect(find.text('The basics'), findsOneWidget);
      await tap(tester, const Key('setupNext'));
      expect(find.text('Find your people'), findsOneWidget);
      await tap(tester, const Key('setupNext'));
      expect(find.text('Looking good!'), findsOneWidget);
      await tap(tester, const Key('setupNext'));
      expect(store.profileComplete, isTrue);
      expect(store.profile.name, 'Jordan');
      expect(find.byKey(const Key('person-cayla')), findsOneWidget);
    },
  );

  testWidgets(
    'like opens a match and the conversation sends a simulated reply',
    (tester) async {
      await boot(tester, demo: true);
      await tap(tester, const Key('Like'));
      expect(find.text('It’s a match!'), findsOneWidget);
      await tap(tester, const Key('sayHello'));
      await tester.enterText(
        find.byKey(const Key('messageComposer')),
        'Coffee?',
      );
      await tap(tester, const Key('sendMessage'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.text('Coffee?'), findsOneWidget);
      expect(
        find.text('Coffee sounds lovely! What’s your favorite spot?'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'pass can be undone; narrow filters show an actionable empty state',
    (tester) async {
      await boot(tester, demo: true);
      await tap(tester, const Key('Pass'));
      expect(find.byKey(const Key('person-sofia')), findsOneWidget);
      await tap(tester, const Key('Undopass'));
      expect(find.byKey(const Key('person-cayla')), findsOneWidget);
      store.saveFilters(Filters(distance: 1));
      await tester.pumpAndSettle();
      expect(find.text('You’re all caught up'), findsOneWidget);
      expect(find.text('Adjust preferences'), findsOneWidget);
    },
  );

  testWidgets('profile editing and sign out keep local changes', (
    tester,
  ) async {
    await boot(tester, demo: true);
    await tester.tap(find.byType(NavigationDestination).at(3));
    await tester.pumpAndSettle();
    await tap(tester, const Key('editProfile'));
    await tester.enterText(find.byKey(const Key('profileName')), 'Taylor');
    await tap(tester, const Key('saveProfile'));
    expect(find.text('Taylor, 27'), findsOneWidget);
    await tap(tester, const Key('settings'));
    await tap(tester, const Key('signOut'));
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('exploreDemo')), findsOneWidget);
    expect(store.profile.name, 'Taylor');
    expect(store.signedIn, isFalse);
  });
}
