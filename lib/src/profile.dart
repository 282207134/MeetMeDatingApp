import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'discovery.dart';
import 'store.dart';
import 'theme.dart';

Future<void> removePhoto(String? path) async {
  if (path == null) return;
  try {
    final file = File(path);
    if (await file.exists()) await file.delete();
  } on FileSystemException {
    /* A missing old photo does not affect the profile. */
  }
}

Future<String> keepPhoto(XFile image) async {
  final directory = await getApplicationDocumentsDirectory();
  final path =
      '${directory.path}/meetme-photo-${DateTime.now().microsecondsSinceEpoch}.jpg';
  await image.saveTo(path);
  return path;
}

Future<void> recoverProfilePhoto(AppStore store) async {
  if (!Platform.isAndroid) return;
  try {
    final response = await ImagePicker().retrieveLostData();
    if (response.files?.isNotEmpty ?? false) {
      final draft = store.profile.copy();
      final old = draft.photoPath;
      draft.photoPath = await keepPhoto(response.files!.first);
      store.saveProfile(draft);
      await store.flush();
      await removePhoto(old);
    }
  } on PlatformException {
    /* The editor offers another try if the picker was interrupted. */
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({required this.store, super.key});
  final AppStore store;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const BrandHeader('My profile', 'A little more you.'),
      Expanded(
        child: ListView(
          key: const Key('profileScroll'),
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
          children: [
            SectionCard(
              child: Column(
                children: [
                  Avatar(profile: store.profile, size: 100),
                  const SizedBox(height: 12),
                  Text(
                    '${store.profile.name}, ${store.profile.age}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${store.profile.city} · ${store.profile.job}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    key: const Key('editProfile'),
                    onPressed: () =>
                        openPage(context, EditProfilePage(store: store)),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit profile'),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      for (final entry in [
                        ('Likes', store.liked.length),
                        ('Connections', store.matches.length),
                        ('Favorites', store.favorites.length),
                      ])
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                '${entry.$2}',
                                style: const TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w800,
                                  color: blue,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                entry.$1,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.blueGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About me',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(store.profile.bio, style: const TextStyle(height: 1.5)),
                  const SizedBox(height: 18),
                  InterestChips(store.profile.interests),
                ],
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => openPage(context, PlusPage(store: store)),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: brandGradient,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 30,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'MeetMe Plus',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            store.premiumPreview
                                ? 'Your demo preview is active'
                                : 'Explore a little more possibility',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.tune, color: blue),
                    title: const Text('Preferences'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => openPage(context, FiltersPage(store: store)),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    key: const Key('settings'),
                    leading: const Icon(Icons.settings_outlined, color: blue),
                    title: const Text('Settings'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => openPage(context, SettingsPage(store: store)),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.help_outline, color: blue),
                    title: const Text('Help & support'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => openPage(context, const HelpPage()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Meetme · Local demo',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.blueGrey),
            ),
          ],
        ),
      ),
    ],
  );
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({required this.store, super.key});
  final AppStore store;
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final draft = widget.store.profile.copy();
  late final name = TextEditingController(text: draft.name),
      age = TextEditingController(text: '${draft.age}'),
      city = TextEditingController(text: draft.city),
      job = TextEditingController(text: draft.job),
      bio = TextEditingController(text: draft.bio);
  final form = GlobalKey<FormState>();
  String? stagedPhoto;
  bool saved = false, picking = false;
  @override
  void dispose() {
    for (final c in [name, age, city, job, bio]) {
      c.dispose();
    }
    if (!saved) removePhoto(stagedPhoto);
    super.dispose();
  }

  Future<void> pickPhoto() async {
    setState(() => picking = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (picked != null) {
        final path = await keepPhoto(picked);
        if (!mounted) {
          await removePhoto(path);
          return;
        }
        await removePhoto(stagedPhoto);
        setState(() {
          stagedPhoto = path;
          draft.photoPath = path;
        });
      }
    } on PlatformException {
      if (mounted) {
        toast(
          context,
          'Photos could not be opened. Check your photo access in Settings.',
        );
      }
    } on FileSystemException {
      if (mounted) {
        toast(context, 'The photo could not be saved. Try another image.');
      }
    } finally {
      if (mounted) setState(() => picking = false);
    }
  }

  void save() {
    if (!form.currentState!.validate()) return;
    if (draft.interests.length < 3) {
      toast(context, 'Choose at least 3 interests.');
      return;
    }
    draft.name = name.text.trim();
    draft.age = int.parse(age.text);
    draft.city = city.text.trim();
    draft.job = job.text.trim();
    draft.bio = bio.text.trim();
    final old = widget.store.profile.photoPath;
    widget.store.saveProfile(draft);
    saved = true;
    if (old != draft.photoPath) removePhoto(old);
    Navigator.pop(context);
    toast(context, 'Profile saved');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Edit profile'),
      actions: [
        TextButton(
          key: const Key('saveProfile'),
          onPressed: picking ? null : save,
          child: const Text('Save'),
        ),
      ],
    ),
    body: SafeArea(
      child: Form(
        key: form,
        child: ListView(
          key: const Key('profileForm'),
          padding: const EdgeInsets.all(24),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            Center(child: Avatar(profile: draft, size: 116)),
            TextButton.icon(
              onPressed: picking ? null : pickPhoto,
              icon: const Icon(Icons.add_a_photo_outlined, size: 18),
              label: Text(picking ? 'Opening photos…' : 'Change photo'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('profileName'),
              controller: name,
              maxLength: 40,
              decoration: const InputDecoration(labelText: 'Name'),
              textInputAction: TextInputAction.next,
              validator: (v) => v!.trim().isEmpty ? 'Enter your name' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: age,
              decoration: const InputDecoration(labelText: 'Age'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.next,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return n == null || n < 18 || n > 99
                    ? 'Use an age from 18 to 99'
                    : null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: city,
              decoration: const InputDecoration(labelText: 'City'),
              textInputAction: TextInputAction.next,
              validator: (v) => v!.trim().isEmpty ? 'Enter your city' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: job,
              decoration: const InputDecoration(labelText: 'Occupation'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('profileBio'),
              controller: bio,
              maxLines: 4,
              maxLength: 280,
              decoration: const InputDecoration(labelText: 'About me'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 20),
            const Text(
              'My interests',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Choose at least 3.',
              style: TextStyle(color: Colors.blueGrey),
            ),
            const SizedBox(height: 16),
            InterestChips(
              interests,
              selected: draft.interests,
              onTap: (s) => setState(() {
                if (!draft.interests.remove(s)) draft.interests.add(s);
              }),
            ),
            const SizedBox(height: 26),
            FilledButton(
              onPressed: picking ? null : save,
              child: const Text('Save changes'),
            ),
          ],
        ),
      ),
    ),
  );
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({required this.store, super.key});
  final AppStore store;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            SectionCard(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  SwitchListTile(
                    key: const Key('notificationsToggle'),
                    title: const Text('Notifications'),
                    subtitle: const Text('Save your demo preference'),
                    value: store.notifications,
                    onChanged: store.setNotifications,
                  ),
                  SwitchListTile(
                    title: const Text('Show online status'),
                    subtitle: const Text('An in-app preference for this demo'),
                    value: store.showOnline,
                    onChanged: store.setOnline,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SectionCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Blocked profiles'),
                    leading: const Icon(Icons.block, color: blue),
                    trailing: Text('${store.blocked.length}'),
                    onTap: () => openPage(context, BlockedPage(store: store)),
                  ),
                  ListTile(
                    title: const Text('Help & support'),
                    leading: const Icon(Icons.help_outline, color: blue),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => openPage(context, const HelpPage()),
                  ),
                  ListTile(
                    title: const Text('About Meetme'),
                    leading: const Icon(Icons.info_outline, color: blue),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => openPage(context, const AboutPage()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              key: const Key('signOut'),
              onPressed: () async {
                if (await confirm(
                  context,
                  'Sign out?',
                  'Your profile and conversations stay on this device.',
                  'Sign out',
                )) {
                  store.signOut();
                  if (context.mounted) {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  }
                }
              },
              child: const Text('Sign out'),
            ),
            const SizedBox(height: 12),
            TextButton(
              key: const Key('resetData'),
              onPressed: () async {
                if (await confirm(
                  context,
                  'Reset all demo data?',
                  'This deletes your local profile, photo and messages and restores the sample profiles.',
                  'Reset',
                )) {
                  final photo = store.profile.photoPath;
                  store.reset();
                  await removePhoto(photo);
                  if (context.mounted) {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  }
                }
              },
              child: const Text(
                'Reset all demo data',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Stored on your device\nFlutter demo · Version 1.0.0',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.blueGrey,
                fontSize: 12,
                height: 1.8,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class BlockedPage extends StatelessWidget {
  const BlockedPage({required this.store, super.key});
  final AppStore store;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text('Blocked profiles')),
      body: store.blocked.isEmpty
          ? const EmptyCard(
              Icons.verified_user_outlined,
              'All clear',
              'You have no blocked profiles.',
            )
          : ListView(
              children: people
                  .where((p) => store.blocked.contains(p.id))
                  .map(
                    (p) => ListTile(
                      leading: Avatar(person: p),
                      title: Text(p.name),
                      subtitle: const Text(
                        'Unblocking does not restore old messages.',
                      ),
                      trailing: TextButton(
                        onPressed: () => store.unblock(p),
                        child: const Text('Unblock'),
                      ),
                    ),
                  )
                  .toList(),
            ),
    ),
  );
}

class PlusPage extends StatefulWidget {
  const PlusPage({required this.store, super.key});
  final AppStore store;
  @override
  State<PlusPage> createState() => _PlusPageState();
}

class _PlusPageState extends State<PlusPage> {
  int plan = 1;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('MeetMe Plus')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(26),
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: brandGradient,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Column(
              children: [
                Icon(Icons.auto_awesome, color: Colors.white, size: 56),
                SizedBox(height: 16),
                Text(
                  'More ways to connect',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 29,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'A preview of what could come next.',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          for (final text in [
            'See who likes you',
            'Make your profile shine',
            'Discover at your own pace',
          ])
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle_outline, color: blue),
              title: Text(text),
            ),
          const SizedBox(height: 16),
          const Text(
            'Choose a preview',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          for (final entry in [
            '1 month',
            '6 months',
            '12 months',
          ].asMap().entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: plan == entry.key
                      ? cyan.withValues(alpha: .16)
                      : Colors.white,
                  side: BorderSide(
                    color: plan == entry.key ? blue : const Color(0xFFDCE7F0),
                  ),
                ),
                onPressed: () => setState(() => plan = entry.key),
                child: Row(
                  children: [
                    Icon(
                      plan == entry.key
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                    ),
                    const SizedBox(width: 12),
                    Text(entry.value),
                    const Spacer(),
                    const Text('Demo', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              widget.store.setPremium(!widget.store.premiumPreview);
              setState(() {});
              toast(
                context,
                widget.store.premiumPreview
                    ? 'Preview active · no payment'
                    : 'Preview ended',
              );
            },
            child: Text(
              widget.store.premiumPreview
                  ? 'End demo preview'
                  : 'Try the demo preview',
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No payment or subscription is created. These options are a visual preview only.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blueGrey, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    ),
  );
}

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Help & support')),
    body: ListView(
      padding: const EdgeInsets.all(22),
      children: [
        const EmptyCard(
          Icons.waving_hand_outlined,
          'Let’s get you started',
          'A few answers for your Meetme demo.',
        ),
        for (final entry in [
          (
            'How do I get a match?',
            'Like Cayla in Discover to see a sample match. Tap Say hello to open a conversation.',
          ),
          (
            'Are the messages real?',
            'No. The sample profiles and replies are simulated. Nothing is sent to another person.',
          ),
          (
            'Where is my data saved?',
            'Your profile, preferences and messages are stored on this device. Sign out keeps them; resetting deletes them.',
          ),
          (
            'Can I change my photo?',
            'Open My profile → Edit profile → Change photo, then select an image from your photo library.',
          ),
          (
            'How do reports work?',
            'Reports are saved locally for this demo. They are not sent to a moderation team.',
          ),
        ])
          Card(
            elevation: 0,
            color: Colors.white,
            child: ExpansionTile(
              title: Text(
                entry.$1,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              children: [
                Text(
                  entry.$2,
                  style: const TextStyle(height: 1.5, color: Colors.blueGrey),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('About Meetme')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(28),
        children: [
          Image.asset('assets/images/logo.png', width: 100, height: 104),
          const SizedBox(height: 20),
          const Text(
            'Meetme',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Swipe. Like. Connect.',
            textAlign: TextAlign.center,
            style: TextStyle(color: blue, fontSize: 17),
          ),
          const SizedBox(height: 32),
          const SectionCard(
            child: Text(
              'Built with Flutter from your Pixso design.\n\nThis is an interactive local demo for adults 18+. Profiles, matches and chat replies are examples. Authentication, remote messaging, location, push notifications, payments and moderation services are not connected.\n\nYour password is never stored. Profile and conversation data stay on this device. You can delete them in Settings → Reset all demo data.',
              style: TextStyle(height: 1.65),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Version 1.0.0',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blueGrey),
          ),
        ],
      ),
    ),
  );
}
