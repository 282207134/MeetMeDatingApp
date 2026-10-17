import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meetme/src/app.dart';
import 'package:meetme/src/store.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  AppStore? current;
  Future<AppStore> boot(WidgetTester tester, {bool demo = true}) async {
    runApp(const SizedBox.shrink());
    await tester.pumpAndSettle();
    current?.dispose();
    final store = await AppStore.load(PreferencesStorage());
    store.reset();
    if (demo) store.startDemo();
    await store.flush();
    current = store;
    runApp(MeetMeApp(key: UniqueKey(), store: store));
    await tester.pumpAndSettle();
    return store;
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

  Future<void> shot(String name) async {
    await binding.takeScreenshot(name);
  }

  Future<void> hideKeyboard(WidgetTester tester) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  }

  testWidgets('registration and profile onboarding on iPhone', (tester) async {
    final store = await boot(tester, demo: false);
    await shot('01-welcome');
    await tap(tester, const Key('createAccount'));
    await tester.enterText(find.byKey(const Key('authName')), 'Jordan');
    await tester.enterText(
      find.byKey(const Key('authEmail')),
      'jordan@example.com',
    );
    await tester.enterText(find.byKey(const Key('authPassword')), 'sample123');
    await hideKeyboard(tester);
    await tap(tester, const Key('adultConfirm'));
    await shot('02-registration');
    await tap(tester, const Key('authSubmit'));
    expect(find.text('The basics'), findsOneWidget);
    await tap(tester, const Key('setupNext'));
    await shot('03-interests');
    await tap(tester, const Key('setupNext'));
    await tap(tester, const Key('setupNext'));
    expect(store.profile.name, 'Jordan');
    expect(store.profileComplete, isTrue);
    expect(find.byKey(const Key('person-cayla')), findsOneWidget);
  });

  testWidgets('discovery, match, messaging and persisted reload on iPhone', (
    tester,
  ) async {
    final store = await boot(tester);
    await shot('04-discover');
    await tap(tester, const Key('Pass'));
    expect(find.byKey(const Key('person-sofia')), findsOneWidget);
    await tap(tester, const Key('Undopass'));
    await tap(tester, const Key('Like'));
    expect(find.text('It’s a match!'), findsOneWidget);
    await shot('05-match');
    await tap(tester, const Key('sayHello'));
    await tester.enterText(
      find.byKey(const Key('messageComposer')),
      'Coffee tomorrow?',
    );
    await tap(tester, const Key('sendMessage'));
    await hideKeyboard(tester);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(
      find.text('Coffee sounds lovely! What’s your favorite spot?'),
      findsOneWidget,
    );
    await shot('06-conversation');
    await store.flush();
    runApp(const SizedBox.shrink());
    await tester.pumpAndSettle();
    final restored = await AppStore.load(PreferencesStorage());
    expect(restored.matchIds, contains('cayla'));
    expect(
      restored.messages['cayla']!.last.text,
      contains('Coffee sounds lovely'),
    );
    store.dispose();
    current = restored;
    runApp(MeetMeApp(key: UniqueKey(), store: restored));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(NavigationDestination).at(1));
    await tester.pumpAndSettle();
    await shot('07-connections');
    await tester.tap(find.byType(NavigationDestination).at(2));
    await tester.pumpAndSettle();
    await shot('08-chats');
  });

  testWidgets('filters, profile editing and settings persist on iPhone', (
    tester,
  ) async {
    final store = await boot(tester);
    await tap(tester, const Key('filters'));
    final slider = find.byKey(const Key('distanceSlider'));
    final rect = tester.getRect(slider);
    await tester.tapAt(Offset(rect.left + 1, rect.center.dy));
    await tester.pumpAndSettle();
    await tap(tester, const Key('applyFilters'));
    expect(store.filters.distance, 1);
    expect(find.text('You’re all caught up'), findsOneWidget);
    await shot('09-empty-discover');
    await tester.tap(find.byType(NavigationDestination).at(3));
    await tester.pumpAndSettle();
    await tap(tester, const Key('editProfile'));
    await tester.enterText(find.byKey(const Key('profileName')), 'Taylor');
    await hideKeyboard(tester);
    await tap(tester, const Key('saveProfile'));
    expect(find.text('Taylor, 27'), findsOneWidget);
    await tester.drag(
      find.byKey(const Key('profileScroll')),
      const Offset(0, 800),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await shot('10-profile');
    await tap(tester, const Key('settings'));
    await tap(tester, const Key('notificationsToggle'));
    expect(store.notifications, isFalse);
    await shot('11-settings');
    await store.flush();
    final restored = await AppStore.load(PreferencesStorage());
    expect(restored.profile.name, 'Taylor');
    expect(restored.notifications, isFalse);
    expect(restored.filters.distance, 1);
    restored.dispose();
    await tap(tester, const Key('resetData'));
    await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('exploreDemo')), findsOneWidget);
    await tap(tester, const Key('exploreDemo'));
    await current!.flush();
  });
}
