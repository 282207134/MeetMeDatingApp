import 'package:flutter/material.dart';
import 'auth.dart';
import 'discovery.dart';
import 'social.dart';
import 'profile.dart';
import 'store.dart';
import 'theme.dart';

class MeetMeApp extends StatelessWidget {
  const MeetMeApp({required this.store, super.key});
  final AppStore store;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Meetme',
    debugShowCheckedModeBanner: false,
    theme: appTheme(),
    home: AnimatedBuilder(
      animation: store,
      builder: (context, _) => !store.signedIn
          ? WelcomePage(store: store)
          : !store.profileComplete
          ? SetupPage(store: store)
          : HomePage(store: store),
    ),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({required this.store, super.key});
  final AppStore store;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        if (store.storageError != null)
          SafeArea(
            bottom: false,
            child: MaterialBanner(
              content: Text(store.storageError!),
              actions: [
                TextButton(
                  onPressed: () => store.saveProfile(store.profile),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        Expanded(
          child: IndexedStack(
            index: store.tab,
            children: [
              DiscoverPage(store: store),
              ConnectionsPage(store: store),
              ChatsPage(store: store),
              ProfilePage(store: store),
            ],
          ),
        ),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: store.tab,
      onDestinationSelected: store.selectTab,
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.explore_outlined),
          selectedIcon: Icon(Icons.explore, color: blue),
          label: 'Discover',
        ),
        const NavigationDestination(
          icon: Icon(Icons.favorite_border),
          selectedIcon: Icon(Icons.favorite, color: blue),
          label: 'Connections',
        ),
        NavigationDestination(
          icon: Badge(
            isLabelVisible: store.unreadCount > 0,
            label: Text('${store.unreadCount}'),
            child: const Icon(Icons.chat_bubble_outline),
          ),
          selectedIcon: const Icon(Icons.chat_bubble, color: blue),
          label: 'Chats',
        ),
        const NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person, color: blue),
          label: 'Profile',
        ),
      ],
    ),
  );
}
