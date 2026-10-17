import 'package:flutter/material.dart';
import 'social.dart';
import 'store.dart';
import 'theme.dart';

Future<void> likePerson(
  BuildContext context,
  AppStore store,
  Person person, {
  bool superLike = false,
}) async {
  if (store.like(person)) {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => MatchPage(store: store, person: person),
      ),
    );
  } else {
    toast(
      context,
      superLike
          ? 'Super like sent to ${person.name}'
          : 'You liked ${person.name}',
    );
  }
}

class DiscoverPage extends StatelessWidget {
  const DiscoverPage({required this.store, super.key});
  final AppStore store;
  @override
  Widget build(BuildContext context) {
    final candidates = store.candidates;
    final p = candidates.isEmpty ? null : candidates.first;
    return Column(
      children: [
        const BrandHeader('Discover', 'A world of hellos.'),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 10, 16, 4),
          child: Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 19, color: blue),
              const SizedBox(width: 5),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: store.profile.city,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(
                        text: ' · Nearby',
                        style: TextStyle(color: Colors.blueGrey),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton.icon(
                key: const Key('filters'),
                onPressed: () => openPage(context, FiltersPage(store: store)),
                icon: const Icon(Icons.tune, size: 20),
                label: const Text('Filters'),
              ),
            ],
          ),
        ),
        Expanded(
          child: p == null
              ? SingleChildScrollView(
                  child: EmptyCard(
                    Icons.travel_explore,
                    'You’re all caught up',
                    'Try a wider search, or revisit the people you passed.',
                    action: Column(
                      children: [
                        FilledButton(
                          onPressed: () =>
                              openPage(context, FiltersPage(store: store)),
                          child: const Text('Adjust preferences'),
                        ),
                        TextButton(
                          onPressed: store.refreshDiscovery,
                          child: const Text('Revisit passed profiles'),
                        ),
                      ],
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: GestureDetector(
                    onHorizontalDragEnd: (details) {
                      if (details.primaryVelocity! > 150) {
                        likePerson(context, store, p);
                      } else if (details.primaryVelocity! < -150) {
                        store.pass(p);
                      }
                    },
                    onTap: () =>
                        openPage(context, PersonPage(store: store, person: p)),
                    child: PhotoCard(person: p, large: true),
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              RoundAction(
                'Undo pass',
                Icons.undo_rounded,
                const Color(0xFFF1B947),
                size: 48,
                onTap: () {
                  if (store.passed.isEmpty) {
                    toast(context, 'No passes to undo yet');
                  } else {
                    store.undoPass();
                  }
                },
              ),
              RoundAction(
                'Pass',
                Icons.close_rounded,
                const Color(0xFFF37883),
                size: 64,
                onTap: p == null ? null : () => store.pass(p),
              ),
              RoundAction(
                'Like',
                Icons.favorite_rounded,
                blue,
                size: 72,
                filled: true,
                onTap: p == null ? null : () => likePerson(context, store, p),
              ),
              RoundAction(
                'Super like',
                Icons.star_rounded,
                const Color(0xFF51C9D9),
                size: 54,
                onTap: p == null
                    ? null
                    : () => likePerson(context, store, p, superLike: true),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text(
            'Sample profiles · Swipe left or right',
            style: TextStyle(fontSize: 11, color: Colors.blueGrey),
          ),
        ),
      ],
    );
  }
}

class PhotoCard extends StatelessWidget {
  const PhotoCard({required this.person, this.large = false, super.key});
  final Person person;
  final bool large;
  @override
  Widget build(BuildContext context) => Container(
    key: Key('person-${person.id}'),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(large ? 28 : 22),
      color: const Color(0xFFDCEBF4),
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/${person.image}.png',
          fit: BoxFit.cover,
          alignment: const Alignment(0, -.3),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [.38, 1],
              colors: [Colors.transparent, Color(0xD9172D44)],
            ),
          ),
        ),
        if (large)
          Positioned(
            top: 18,
            left: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .95),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.circle, size: 7, color: Color(0xFF39B98C)),
                  SizedBox(width: 6),
                  Text(
                    'Active recently',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        Positioned(
          left: large ? 22 : 14,
          right: 12,
          bottom: large ? 23 : 14,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      '${person.name}, ${person.age}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: large ? 31 : 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (person.verified) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.verified, color: cyan, size: large ? 22 : 16),
                  ],
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: Colors.white,
                    size: large ? 16 : 13,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${person.distance} km away',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: large ? 14 : 12,
                    ),
                  ),
                ],
              ),
              if (large) ...[
                const SizedBox(height: 7),
                Text(
                  person.job,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class RoundAction extends StatelessWidget {
  const RoundAction(
    this.label,
    this.icon,
    this.color, {
    required this.onTap,
    this.size = 60,
    this.filled = false,
    super.key,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final double size;
  final bool filled;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: SizedBox(
      width: size,
      height: size,
      child: Material(
        color: filled ? color : Colors.white,
        shape: const CircleBorder(),
        elevation: 3,
        shadowColor: blue.withValues(alpha: .14),
        child: IconButton(
          key: Key(label.replaceAll(' ', '')),
          tooltip: label,
          onPressed: onTap,
          iconSize: size * .47,
          icon: Icon(
            icon,
            color: onTap == null
                ? Colors.grey.shade300
                : filled
                ? Colors.white
                : color,
          ),
        ),
      ),
    ),
  );
}

class FiltersPage extends StatefulWidget {
  const FiltersPage({required this.store, super.key});
  final AppStore store;
  @override
  State<FiltersPage> createState() => _FiltersPageState();
}

class _FiltersPageState extends State<FiltersPage> {
  late Filters filters = widget.store.filters.copy();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Discovery preferences'),
      actions: [
        TextButton(
          onPressed: () => setState(() => filters = Filters()),
          child: const Text('Reset'),
        ),
      ],
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Your kind of connection',
            style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          const Text(
            'Fine-tune who appears in Discover.',
            style: TextStyle(color: Colors.blueGrey),
          ),
          const SizedBox(height: 28),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Age range · ${filters.minAge}–${filters.maxAge}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                RangeSlider(
                  key: const Key('ageRange'),
                  values: RangeValues(
                    filters.minAge.toDouble(),
                    filters.maxAge.toDouble(),
                  ),
                  min: 18,
                  max: 99,
                  divisions: 81,
                  labels: RangeLabels('${filters.minAge}', '${filters.maxAge}'),
                  onChanged: (v) => setState(() {
                    filters.minAge = v.start.round();
                    filters.maxAge = v.end.round();
                  }),
                ),
                const SizedBox(height: 24),
                Text(
                  'Maximum distance · ${filters.distance} km',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Slider(
                  key: const Key('distanceSlider'),
                  value: filters.distance.toDouble(),
                  min: 1,
                  max: 100,
                  divisions: 99,
                  label: '${filters.distance} km',
                  onChanged: (v) =>
                      setState(() => filters.distance = v.round()),
                ),
                const Divider(height: 32),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Verified profiles only'),
                  value: filters.verifiedOnly,
                  onChanged: (v) => setState(() => filters.verifiedOnly = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          FilledButton(
            key: const Key('applyFilters'),
            onPressed: () {
              widget.store.saveFilters(filters);
              Navigator.pop(context);
            },
            child: const Text('Apply preferences'),
          ),
        ],
      ),
    ),
  );
}

class PersonPage extends StatelessWidget {
  const PersonPage({required this.store, required this.person, super.key});
  final AppStore store;
  final Person person;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: Text(person.name),
        actions: [
          IconButton(
            tooltip: 'Favorite',
            onPressed: () => store.favorite(person),
            icon: Icon(
              store.favorites.contains(person.id)
                  ? Icons.bookmark
                  : Icons.bookmark_border,
              color: blue,
            ),
          ),
          IconButton(
            tooltip: 'Report profile',
            onPressed: () => reportPerson(context, store, person),
            icon: const Icon(Icons.flag_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
        children: [
          SizedBox(height: 390, child: PhotoCard(person: person, large: true)),
          const SizedBox(height: 24),
          const Text(
            'About me',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(person.bio, style: const TextStyle(fontSize: 16, height: 1.6)),
          const SizedBox(height: 24),
          const Text(
            'We could talk about…',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          InterestChips(person.interests),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: () {
              if (store.matchIds.contains(person.id)) {
                Navigator.pop(context);
                openChat(context, store, person);
              } else {
                Navigator.pop(context);
                likePerson(context, store, person);
              }
            },
            child: Text(
              store.matchIds.contains(person.id)
                  ? 'Send a message'
                  : 'Like ${person.name}',
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Example profile for the local demo.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blueGrey, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

class MatchPage extends StatelessWidget {
  const MatchPage({required this.store, required this.person, super.key});
  final AppStore store;
  final Person person;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(gradient: brandGradient),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo.png', width: 90, height: 92),
              const SizedBox(height: 28),
              const Text(
                'It’s a match!',
                style: TextStyle(
                  fontSize: 43,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You and ${person.name} liked each other.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, color: Colors.white),
              ),
              const SizedBox(height: 44),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Avatar(profile: store.profile, size: 116),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.favorite, color: Colors.white, size: 30),
                  ),
                  Avatar(person: person, size: 116),
                ],
              ),
              const SizedBox(height: 48),
              FilledButton(
                key: const Key('sayHello'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: blue,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  store.selectTab(2);
                  openChat(context, store, person);
                },
                child: const Text('Say hello'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Keep discovering',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'A sample match in your local demo.',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
