import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const interests = [
  'Travel',
  'Coffee',
  'Music',
  'Art',
  'Hiking',
  'Books',
  'Movies',
  'Food',
  'Design',
  'Fitness',
  'Gaming',
  'Pets',
];

class Person {
  const Person(
    this.id,
    this.name,
    this.age,
    this.city,
    this.distance,
    this.job,
    this.image,
    this.bio,
    this.interests, {
    this.likesYou = true,
    this.verified = true,
  });
  final String id, name, city, job, image, bio;
  final int age, distance;
  final List<String> interests;
  final bool likesYou, verified;
}

const people = [
  Person(
    'cayla',
    'Cayla',
    29,
    'Tokyo',
    2,
    'Designer',
    'cayla',
    'Collecting little moments, good coffee, and places I haven’t been. Tell me about your favorite hidden gem.',
    ['Travel', 'Coffee', 'Photography', 'Hiking'],
  ),
  Person(
    'sofia',
    'Sofia',
    26,
    'Yokohama',
    6,
    'Photographer',
    'sofia',
    'Usually by the ocean or looking for the best brunch spot. A good playlist makes everything better.',
    ['Music', 'Travel', 'Art', 'Food'],
    likesYou: false,
  ),
  Person(
    'emma',
    'Emma',
    27,
    'Tokyo',
    4,
    'Editor',
    'emma',
    'Bookstores, slow Sundays, and conversations that make you forget to check your phone.',
    ['Books', 'Coffee', 'Art', 'Movies'],
  ),
  Person(
    'noah',
    'Noah',
    28,
    'Tokyo',
    8,
    'Architect',
    'avatar_me',
    'A little design, a little adventure. Always up for trying something new.',
    ['Design', 'Hiking', 'Travel'],
  ),
  Person(
    'maya',
    'Maya',
    25,
    'Tokyo',
    12,
    'Illustrator',
    'cayla',
    'Making things and making memories. Looking for a kind heart and a curious mind.',
    ['Art', 'Music', 'Food'],
  ),
];

class Profile {
  Profile({
    this.name = 'Alex',
    this.age = 27,
    this.email = '',
    this.city = 'Tokyo',
    this.job = 'Product designer',
    this.bio =
        'Curious about the world. Happiest with a good coffee, a new playlist, and a little adventure.',
    this.gender = 'Man',
    this.intention = 'A meaningful connection',
    List<String>? interests,
    this.photoPath,
  }) : interests = interests ?? ['Travel', 'Coffee', 'Design'];
  String name, email, city, job, bio, gender, intention;
  int age;
  List<String> interests;
  String? photoPath;
  Map<String, dynamic> toJson() => {
    'name': name,
    'age': age,
    'email': email,
    'city': city,
    'job': job,
    'bio': bio,
    'gender': gender,
    'intention': intention,
    'interests': interests,
    'photoPath': photoPath,
  };
  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
    name: j['name'] ?? 'Alex',
    age: j['age'] ?? 27,
    email: j['email'] ?? '',
    city: j['city'] ?? 'Tokyo',
    job: j['job'] ?? 'Product designer',
    bio: j['bio'] ?? '',
    gender: j['gender'] ?? 'Man',
    intention: j['intention'] ?? 'A meaningful connection',
    interests: List<String>.from(
      j['interests'] ?? ['Travel', 'Coffee', 'Design'],
    ),
    photoPath: j['photoPath'],
  );
  Profile copy() =>
      Profile.fromJson(toJson()..['interests'] = List<String>.from(interests));
}

class Filters {
  Filters({
    this.minAge = 18,
    this.maxAge = 40,
    this.distance = 50,
    this.verifiedOnly = false,
  });
  int minAge, maxAge, distance;
  bool verifiedOnly;
  Map<String, dynamic> toJson() => {
    'minAge': minAge,
    'maxAge': maxAge,
    'distance': distance,
    'verifiedOnly': verifiedOnly,
  };
  factory Filters.fromJson(Map<String, dynamic> j) => Filters(
    minAge: j['minAge'] ?? 18,
    maxAge: j['maxAge'] ?? 40,
    distance: j['distance'] ?? 50,
    verifiedOnly: j['verifiedOnly'] ?? false,
  );
  Filters copy() => Filters.fromJson(toJson());
}

class Message {
  Message(this.text, this.mine, {DateTime? date})
    : date = date ?? DateTime.now();
  final String text;
  final bool mine;
  final DateTime date;
  Map<String, dynamic> toJson() => {
    'text': text,
    'mine': mine,
    'date': date.toIso8601String(),
  };
  factory Message.fromJson(Map<String, dynamic> j) =>
      Message(j['text'], j['mine'], date: DateTime.parse(j['date']));
}

abstract class LocalStorage {
  Future<String?> read();
  Future<void> write(String value);
}

class PreferencesStorage implements LocalStorage {
  static const key = 'meetme.flutter.state.v1';
  final _preferences = SharedPreferencesAsync();
  @override
  Future<String?> read() => _preferences.getString(key);
  @override
  Future<void> write(String value) => _preferences.setString(key, value);
}

class AppStore extends ChangeNotifier {
  AppStore(
    this.storage, {
    this.replyDelay = const Duration(milliseconds: 1100),
  });
  final LocalStorage storage;
  final Duration replyDelay;
  bool signedIn = false, profileComplete = false;
  Profile profile = Profile();
  Filters filters = Filters();
  final Set<String> liked = {}, favorites = {}, blocked = {};
  final List<String> passed = [], matchIds = ['emma', 'noah'];
  final List<String> reports = [];
  Map<String, List<Message>> messages = {
    'emma': [
      Message('Hi Alex! Your coffee recommendation looks so good.', false),
      Message('It’s my favorite little spot in Tokyo!', true),
      Message('We should swap recommendations sometime.', false),
    ],
    'noah': [
      Message('Hey! Have you tried the hiking trail near Kamakura?', false),
    ],
  };
  Map<String, int> unread = {'emma': 1, 'noah': 1};
  bool notifications = true, showOnline = true, premiumPreview = false;
  int tab = 0;
  String? activeChat, storageError;
  Future<void> _pendingWrite = Future.value();
  final Set<Timer> _timers = {};
  bool _disposed = false;

  static Future<AppStore> load(
    LocalStorage storage, {
    Duration replyDelay = const Duration(milliseconds: 1100),
  }) async {
    var result = AppStore(storage, replyDelay: replyDelay);
    try {
      final saved = await storage.read();
      if (saved != null) {
        result._restore(jsonDecode(saved) as Map<String, dynamic>);
      }
    } catch (_) {
      result.dispose();
      result = AppStore(storage, replyDelay: replyDelay)
        ..storageError =
            'Saved data could not be loaded. A fresh demo is ready.';
    }
    return result;
  }

  Person person(String id) => people.firstWhere((p) => p.id == id);
  List<Person> get candidates => people
      .where(
        (p) =>
            !liked.contains(p.id) &&
            !passed.contains(p.id) &&
            !blocked.contains(p.id) &&
            !matchIds.contains(p.id) &&
            p.age >= filters.minAge &&
            p.age <= filters.maxAge &&
            p.distance <= filters.distance &&
            (!filters.verifiedOnly || p.verified),
      )
      .toList();
  List<Person> get matches => people
      .where((p) => matchIds.contains(p.id) && !blocked.contains(p.id))
      .toList();
  List<Person> get likesYou => people
      .where(
        (p) =>
            p.likesYou && !blocked.contains(p.id) && !matchIds.contains(p.id),
      )
      .toList();
  int get unreadCount => unread.values.fold(0, (a, b) => a + b);

  void selectTab(int value) {
    tab = value;
    notifyListeners();
  }

  void startDemo() {
    signedIn = true;
    profileComplete = true;
    _changed();
  }

  void signIn({
    required String name,
    required String email,
    required bool create,
  }) {
    if (name.trim().isNotEmpty) profile.name = name.trim();
    profile.email = email.trim();
    signedIn = true;
    if (create) profileComplete = false;
    _changed();
  }

  void saveProfile(Profile value, {bool finish = false}) {
    profile = value.copy();
    if (finish) profileComplete = true;
    _changed();
  }

  void saveFilters(Filters value) {
    filters = value.copy();
    _changed();
  }

  bool like(Person p) {
    if (blocked.contains(p.id)) return false;
    liked.add(p.id);
    passed.remove(p.id);
    final newMatch = p.likesYou && !matchIds.contains(p.id);
    if (newMatch) {
      matchIds.add(p.id);
      messages[p.id] = [Message('You matched! Say hello to ${p.name}.', false)];
      unread[p.id] = 1;
    }
    _changed();
    return newMatch;
  }

  void pass(Person p) {
    if (!passed.contains(p.id)) passed.add(p.id);
    _changed();
  }

  void undoPass() {
    if (passed.isNotEmpty) passed.removeLast();
    _changed();
  }

  void refreshDiscovery() {
    passed.clear();
    liked.clear();
    _changed();
  }

  void favorite(Person p) {
    if (!favorites.remove(p.id)) favorites.add(p.id);
    _changed();
  }

  void readChat(Person p) {
    activeChat = p.id;
    unread[p.id] = 0;
    _changed();
  }

  void leaveChat(Person p) {
    if (activeChat == p.id) activeChat = null;
  }

  void send(String text, Person p) {
    final clean = text.trim();
    if (clean.isEmpty || blocked.contains(p.id) || !matchIds.contains(p.id)) {
      return;
    }
    messages.putIfAbsent(p.id, () => []).add(Message(clean, true));
    _changed();
    late final Timer timer;
    timer = Timer(replyDelay, () {
      _timers.remove(timer);
      if (_disposed || blocked.contains(p.id) || !matchIds.contains(p.id)) {
        return;
      }
      messages[p.id]!.add(
        Message(
          clean.toLowerCase().contains('coffee')
              ? 'Coffee sounds lovely! What’s your favorite spot?'
              : 'That sounds lovely! I’d like to hear more about it.',
          false,
        ),
      );
      if (activeChat != p.id) unread[p.id] = (unread[p.id] ?? 0) + 1;
      _changed();
    });
    _timers.add(timer);
  }

  void unmatch(Person p) {
    matchIds.remove(p.id);
    messages.remove(p.id);
    unread.remove(p.id);
    _changed();
  }

  void block(Person p) {
    blocked.add(p.id);
    unmatch(p);
  }

  void unblock(Person p) {
    blocked.remove(p.id);
    _changed();
  }

  void report(Person p, String reason) {
    reports.add('${p.id}: $reason');
    _changed();
  }

  void setNotifications(bool value) {
    notifications = value;
    _changed();
  }

  void setOnline(bool value) {
    showOnline = value;
    _changed();
  }

  void setPremium(bool value) {
    premiumPreview = value;
    _changed();
  }

  void signOut() {
    signedIn = false;
    tab = 0;
    activeChat = null;
    _changed();
  }

  void reset() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
    final fresh = AppStore(storage);
    _restore(fresh.toJson());
    fresh.dispose();
    tab = 0;
    activeChat = null;
    _changed();
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    'signedIn': signedIn,
    'profileComplete': profileComplete,
    'profile': profile.toJson(),
    'filters': filters.toJson(),
    'liked': liked.toList(),
    'passed': passed,
    'favorites': favorites.toList(),
    'blocked': blocked.toList(),
    'matches': matchIds,
    'messages': messages.map(
      (id, items) => MapEntry(id, items.map((m) => m.toJson()).toList()),
    ),
    'unread': unread,
    'notifications': notifications,
    'showOnline': showOnline,
    'premiumPreview': premiumPreview,
    'reports': reports,
  };
  void _restore(Map<String, dynamic> j) {
    signedIn = j['signedIn'] ?? false;
    profileComplete = j['profileComplete'] ?? false;
    profile = Profile.fromJson(j['profile']);
    filters = Filters.fromJson(j['filters']);
    final known = people.map((p) => p.id).toSet();
    liked
      ..clear()
      ..addAll(List<String>.from(j['liked']).where(known.contains));
    passed
      ..clear()
      ..addAll(List<String>.from(j['passed']).where(known.contains));
    favorites
      ..clear()
      ..addAll(List<String>.from(j['favorites']).where(known.contains));
    blocked
      ..clear()
      ..addAll(List<String>.from(j['blocked']).where(known.contains));
    matchIds
      ..clear()
      ..addAll(List<String>.from(j['matches']).where(known.contains));
    reports
      ..clear()
      ..addAll(List<String>.from(j['reports']));
    messages = (j['messages'] as Map<String, dynamic>).map(
      (id, items) => MapEntry(
        id,
        (items as List)
            .map((m) => Message.fromJson(Map<String, dynamic>.from(m)))
            .toList(),
      ),
    );
    unread = Map<String, int>.from(j['unread']);
    notifications = j['notifications'];
    showOnline = j['showOnline'];
    premiumPreview = j['premiumPreview'];
  }

  void _changed() {
    final snapshot = jsonEncode(toJson());
    _pendingWrite = _pendingWrite.then((_) async {
      try {
        await storage.write(snapshot);
        final hadError = storageError != null;
        storageError = null;
        if (hadError && !_disposed) notifyListeners();
      } catch (_) {
        storageError =
            'Your latest changes could not be saved. Please try again.';
        if (!_disposed) notifyListeners();
      }
    });
    notifyListeners();
  }

  Future<void> flush() => _pendingWrite;
  @override
  void dispose() {
    _disposed = true;
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }
}
