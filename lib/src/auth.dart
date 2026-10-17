import 'package:flutter/material.dart';
import 'store.dart';
import 'theme.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({required this.store, super.key});
  final AppStore store;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        Expanded(
          flex: 6,
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: brandGradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(52)),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 122,
                    height: 124,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Meetme',
                    style: TextStyle(
                      fontSize: 54,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Swipe. Like. Connect.',
                    style: TextStyle(fontSize: 21, color: Colors.white),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final p in people.take(3))
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 7),
                          child: Avatar(person: p, size: 60),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 26, 28, 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Your next hello starts here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 22),
                  FilledButton(
                    key: const Key('createAccount'),
                    onPressed: () =>
                        openPage(context, AuthPage(store: store, create: true)),
                    child: const Text('Create an account'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => openPage(
                      context,
                      AuthPage(store: store, create: false),
                    ),
                    child: const Text('I already have an account'),
                  ),
                  TextButton(
                    key: const Key('exploreDemo'),
                    onPressed: store.startDemo,
                    child: const Text('Explore the demo'),
                  ),
                  const Text(
                    'A local demo for adults 18+. Profiles and conversations are examples.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blueGrey,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class AuthPage extends StatefulWidget {
  const AuthPage({required this.store, required this.create, super.key});
  final AppStore store;
  final bool create;
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController();
  bool adult = false, hidden = true;
  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  void submit() {
    if (!form.currentState!.validate()) return;
    if (!adult) {
      toast(context, 'Please confirm that you are 18 or older.');
      return;
    }
    FocusScope.of(context).unfocus();
    widget.store.signIn(
      name: name.text,
      email: email.text,
      create: widget.create,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.create ? 'Create your account' : 'Welcome back'),
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Form(
          key: form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Icon(Icons.favorite, color: blue, size: 42),
              const SizedBox(height: 20),
              Text(
                widget.create
                    ? 'Let’s make a connection.'
                    : 'Good to see you again.',
                style: const TextStyle(
                  fontSize: 29,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'This demo saves your profile on this device. It does not create an online account.',
                style: TextStyle(color: Colors.blueGrey, height: 1.5),
              ),
              const SizedBox(height: 28),
              if (widget.create) ...[
                TextFormField(
                  key: const Key('authName'),
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      v!.trim().isEmpty ? 'Enter your name' : null,
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                key: const Key('authEmail'),
                controller: email,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v!.trim())
                    ? null
                    : 'Enter a valid email',
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('authPassword'),
                controller: password,
                obscureText: hidden,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    tooltip: hidden ? 'Show password' : 'Hide password',
                    icon: Icon(
                      hidden
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => hidden = !hidden),
                  ),
                ),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                validator: (v) =>
                    (v?.length ?? 0) < 6 ? 'Use at least 6 characters' : null,
              ),
              const SizedBox(height: 8),
              const Text(
                'For this form only. Your password is never saved.',
                style: TextStyle(fontSize: 12, color: Colors.blueGrey),
              ),
              const SizedBox(height: 18),
              CheckboxListTile(
                key: const Key('adultConfirm'),
                value: adult,
                onChanged: (v) => setState(() => adult = v!),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('I am 18 or older'),
              ),
              const SizedBox(height: 18),
              FilledButton(
                key: const Key('authSubmit'),
                onPressed: submit,
                child: Text(
                  widget.create ? 'Create account' : 'Continue locally',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class SetupPage extends StatefulWidget {
  const SetupPage({required this.store, super.key});
  final AppStore store;
  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  late final Profile draft = widget.store.profile.copy();
  late final name = TextEditingController(text: draft.name),
      city = TextEditingController(text: draft.city);
  final form = GlobalKey<FormState>();
  int step = 0;
  @override
  void dispose() {
    name.dispose();
    city.dispose();
    super.dispose();
  }

  void next() {
    if (step == 0) {
      if (!form.currentState!.validate()) return;
      draft.name = name.text.trim();
      draft.city = city.text.trim();
      FocusScope.of(context).unfocus();
    }
    if (step == 1 && draft.interests.length < 3) {
      toast(context, 'Choose at least 3 interests.');
      return;
    }
    if (step < 2) {
      setState(() => step++);
    } else {
      widget.store.saveProfile(draft, finish: true);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: step > 0
          ? BackButton(onPressed: () => setState(() => step--))
          : null,
      title: const Text('Make it you'),
    ),
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                for (var i = 0; i < 3; i++)
                  Expanded(
                    child: Container(
                      height: 5,
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: i <= step ? blue : const Color(0xFFDCE7F0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ['The basics', 'Find your people', 'Looking good!'][step],
                    style: const TextStyle(
                      fontSize: 31,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    [
                      'A few details for your first hello.',
                      'Pick at least 3 things you love.',
                      'Your profile is ready for a new connection.',
                    ][step],
                    style: const TextStyle(color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 28),
                  if (step == 0)
                    Form(
                      key: form,
                      child: Column(
                        children: [
                          TextFormField(
                            key: const Key('setupName'),
                            controller: name,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                            ),
                            textInputAction: TextInputAction.next,
                            validator: (v) =>
                                v!.trim().isEmpty ? 'Enter your name' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: city,
                            decoration: const InputDecoration(
                              labelText: 'City',
                            ),
                            textInputAction: TextInputAction.done,
                            validator: (v) =>
                                v!.trim().isEmpty ? 'Enter your city' : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<int>(
                            initialValue: draft.age,
                            decoration: const InputDecoration(labelText: 'Age'),
                            items: [
                              for (var age = 18; age <= 99; age++)
                                DropdownMenuItem(
                                  value: age,
                                  child: Text('$age'),
                                ),
                            ],
                            onChanged: (v) => draft.age = v!,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: draft.gender,
                            decoration: const InputDecoration(
                              labelText: 'I identify as',
                            ),
                            items:
                                [
                                      'Man',
                                      'Woman',
                                      'Non-binary',
                                      'Prefer not to say',
                                    ]
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) => draft.gender = v!,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: draft.intention,
                            decoration: const InputDecoration(
                              labelText: 'Looking for',
                            ),
                            items:
                                [
                                      'A meaningful connection',
                                      'New friends',
                                      'Seeing where it goes',
                                    ]
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) => draft.intention = v!,
                          ),
                        ],
                      ),
                    ),
                  if (step == 1)
                    InterestChips(
                      interests,
                      selected: draft.interests,
                      onTap: (item) => setState(() {
                        if (!draft.interests.remove(item)) {
                          draft.interests.add(item);
                        }
                      }),
                    ),
                  if (step == 2)
                    SectionCard(
                      child: Column(
                        children: [
                          Avatar(profile: draft, size: 125),
                          const SizedBox(height: 20),
                          Text(
                            '${draft.name}, ${draft.age}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            draft.city,
                            style: const TextStyle(color: Colors.blueGrey),
                          ),
                          const SizedBox(height: 24),
                          InterestChips(draft.interests),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
            child: FilledButton(
              key: const Key('setupNext'),
              onPressed: next,
              child: Text(step == 2 ? 'Start discovering' : 'Continue'),
            ),
          ),
        ],
      ),
    ),
  );
}
