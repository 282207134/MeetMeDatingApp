import 'package:flutter/material.dart';
import 'discovery.dart';
import 'store.dart';
import 'theme.dart';

void openChat(BuildContext context, AppStore store, Person person) {
  store.readChat(person);
  openPage(context, ChatPage(store: store, person: person));
}

Future<void> reportPerson(
  BuildContext context,
  AppStore store,
  Person person,
) async {
  final reason = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(
            title: Text(
              'Report profile',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Demo reports are saved on this device only.'),
          ),
          for (final reason in [
            'Inappropriate content',
            'Fake profile',
            'Other concern',
          ])
            ListTile(
              title: Text(reason),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(context, reason),
            ),
        ],
      ),
    ),
  );
  if (reason != null) {
    store.report(person, reason);
    if (context.mounted) {
      toast(context, 'Report saved on this device · demo only');
    }
  }
}

class ConnectionsPage extends StatefulWidget {
  const ConnectionsPage({required this.store, super.key});
  final AppStore store;
  @override
  State<ConnectionsPage> createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends State<ConnectionsPage> {
  int selection = 0;
  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final visible = [
      store.matches,
      store.likesYou,
      people
          .where(
            (p) =>
                store.favorites.contains(p.id) && !store.blocked.contains(p.id),
          )
          .toList(),
      people
          .where(
            (p) => store.passed.contains(p.id) && !store.blocked.contains(p.id),
          )
          .toList(),
    ][selection];
    return Column(
      children: [
        const BrandHeader('Connections', 'Good things start with a hello.'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
          child: Row(
            children: [
              for (final entry in [
                'Matches',
                'Liked you',
                'Favorites',
                'Passed',
              ].asMap().entries)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(entry.value),
                    selected: selection == entry.key,
                    onSelected: (_) => setState(() => selection = entry.key),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? EmptyCard(
                  Icons.favorite_outline,
                  'More connections ahead',
                  'Explore profiles and start a conversation.',
                  action: FilledButton(
                    onPressed: () => store.selectTab(0),
                    child: const Text('Discover people'),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 2, 20, 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: .7,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: visible.length,
                  itemBuilder: (context, i) => GestureDetector(
                    onTap: () => openPage(
                      context,
                      PersonPage(store: store, person: visible[i]),
                    ),
                    child: PhotoCard(person: visible[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

class ChatsPage extends StatefulWidget {
  const ChatsPage({required this.store, super.key});
  final AppStore store;
  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  String search = '';
  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final visible = store.matches
        .where((p) => p.name.toLowerCase().contains(search.toLowerCase()))
        .toList();
    return Column(
      children: [
        const BrandHeader('Chats', 'A little hello can go a long way.'),
        Padding(
          padding: const EdgeInsets.all(20),
          child: TextField(
            key: const Key('chatSearch'),
            onChanged: (s) => setState(() => search = s),
            decoration: const InputDecoration(
              hintText: 'Search conversations',
              prefixIcon: Icon(Icons.search),
            ),
            textInputAction: TextInputAction.search,
          ),
        ),
        if (store.matches.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: store.matches.length,
              separatorBuilder: (_, index) => const SizedBox(width: 18),
              itemBuilder: (context, i) {
                final p = store.matches[i];
                return InkWell(
                  onTap: () => openChat(context, store, p),
                  child: Column(
                    children: [
                      Avatar(person: p, size: 64),
                      const SizedBox(height: 5),
                      Text(
                        p.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Messages',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '${visible.length} conversations',
                style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
              ),
            ],
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? const EmptyCard(
                  Icons.chat_bubble_outline,
                  'Say hello to someone new',
                  'Your conversations will appear here.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  itemCount: visible.length,
                  separatorBuilder: (_, index) => const Divider(
                    indent: 84,
                    height: 1,
                    color: Color(0xFFE7EFF6),
                  ),
                  itemBuilder: (context, i) {
                    final p = visible[i];
                    final chat = store.messages[p.id] ?? [];
                    final unread = store.unread[p.id] ?? 0;
                    return ListTile(
                      key: Key('chat-${p.id}'),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 9,
                      ),
                      leading: Avatar(person: p, size: 58),
                      title: Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          children: [
                            Text(
                              p.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 5),
                            if (p.verified)
                              const Icon(Icons.verified, color: blue, size: 15),
                          ],
                        ),
                      ),
                      subtitle: Text(
                        chat.isEmpty
                            ? 'Start a conversation'
                            : '${chat.last.mine ? 'You: ' : ''}${chat.last.text}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 13,
                        ),
                      ),
                      trailing: unread > 0
                          ? CircleAvatar(
                              radius: 11,
                              backgroundColor: blue,
                              child: Text(
                                '$unread',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: Colors.blueGrey,
                            ),
                      onTap: () => openChat(context, store, p),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({required this.store, required this.person, super.key});
  final AppStore store;
  final Person person;
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final composer = TextEditingController();
  final scroll = ScrollController();
  int lastCount = -1;
  @override
  void dispose() {
    widget.store.leaveChat(widget.person);
    composer.dispose();
    scroll.dispose();
    super.dispose();
  }

  void send() {
    widget.store.send(composer.text, widget.person);
    composer.clear();
  }

  Future<void> menu(String action) async {
    final p = widget.person, store = widget.store;
    if (action == 'profile') {
      openPage(context, PersonPage(store: store, person: p));
      return;
    }
    if (action == 'report') {
      await reportPerson(context, store, p);
      return;
    }
    final block = action == 'block';
    if (await confirm(
      context,
      block ? 'Block ${p.name}?' : 'Unmatch ${p.name}?',
      'This removes the connection and its messages from this demo.',
      block ? 'Block' : 'Unmatch',
    )) {
      if (block) {
        store.block(p);
      } else {
        store.unmatch(p);
      }
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.store,
    builder: (context, _) {
      final p = widget.person, store = widget.store;
      final chat = store.messages[p.id] ?? [];
      if (lastCount != chat.length) {
        lastCount = chat.length;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && scroll.hasClients) {
            scroll.animateTo(
              scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      }
      return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Avatar(person: p, size: 40),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Demo conversation',
                    style: TextStyle(color: Colors.blueGrey, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              tooltip: 'Conversation options',
              onSelected: menu,
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'profile', child: Text('View profile')),
                PopupMenuItem(value: 'report', child: Text('Report')),
                PopupMenuItem(value: 'unmatch', child: Text('Unmatch')),
                PopupMenuItem(value: 'block', child: Text('Block')),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              color: cyan.withValues(alpha: .12),
              child: const Text(
                'Replies are simulated and saved on this device.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: blue),
              ),
            ),
            Expanded(
              child: ListView.builder(
                key: const Key('messageList'),
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                itemCount: chat.length + 1,
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return const Padding(
                      padding: EdgeInsets.only(bottom: 24),
                      child: Text(
                        'YOUR CONNECTION STARTS HERE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blueGrey,
                          letterSpacing: 1.3,
                        ),
                      ),
                    );
                  }
                  final m = chat[i - 1];
                  return Align(
                    alignment: m.mine
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.sizeOf(context).width * .76,
                      ),
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.fromLTRB(16, 13, 16, 10),
                      decoration: BoxDecoration(
                        color: m.mine ? blue : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(19),
                          topRight: const Radius.circular(19),
                          bottomLeft: Radius.circular(m.mine ? 19 : 4),
                          bottomRight: Radius.circular(m.mine ? 4 : 19),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            m.text,
                            style: TextStyle(
                              fontSize: 15,
                              color: m.mine ? Colors.white : ink,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${m.date.hour.toString().padLeft(2, '0')}:${m.date.minute.toString().padLeft(2, '0')}${m.mine ? '  ✓' : ''}',
                            style: TextStyle(
                              fontSize: 10,
                              color: m.mine ? Colors.white70 : Colors.blueGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('messageComposer'),
                        controller: composer,
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Write a message…',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filled(
                      key: const Key('sendMessage'),
                      tooltip: 'Send message',
                      onPressed: send,
                      icon: const Icon(Icons.arrow_upward),
                      style: IconButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        backgroundColor: blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
