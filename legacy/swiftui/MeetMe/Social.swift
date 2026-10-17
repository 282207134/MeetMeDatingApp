import SwiftUI

enum ConnectionCategory: String, CaseIterable, Identifiable {
    case matches = "Matches", likedYou = "Liked you", favorites = "Favorites", passed = "Passed"
    var id: String { rawValue }
}

struct ConnectionsView: View {
    @Environment(AppStore.self) private var store
    @State private var category: ConnectionCategory = .matches
    @State private var detail: Person?
    private var people: [Person] {
        switch category {
        case .matches: store.matches
        case .likedYou: store.peopleWhoLikeYou
        case .favorites: store.state.favorites.compactMap(store.person).filter { !store.state.blocked.contains($0.id) }
        case .passed: store.state.passed.compactMap(store.person).filter { !store.state.blocked.contains($0.id) }
        }
    }
    var body: some View {
        VStack(spacing: 18) {
            BrandHeader(title: "Your kind of people.", subtitle: "A spark is only the beginning.")
            Picker("Connections", selection: $category) {
                ForEach(ConnectionCategory.allCases) { Text($0.rawValue).tag($0) }
            }.pickerStyle(.segmented).padding(.horizontal, 18).accessibilityIdentifier("connections-category")
            ScrollView {
                if people.isEmpty {
                    EmptyCard(icon: category == .matches ? "heart" : "sparkles", title: "Room for something new.", message: "\(category.rawValue) will appear here as you explore and connect.").padding(.top, 50)
                    Button("Back to discovering") { store.selectedTab = 0 }.buttonStyle(.borderedProminent)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(people) { person in
                            Button { detail = person } label: {
                                VStack(alignment: .leading, spacing: 0) {
                                    Image(person.image).resizable().scaledToFill().frame(height: 200).clipped()
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack(spacing: 5) {
                                            Text("\(person.name), \(person.age)").font(.headline)
                                            Image(systemName: "checkmark.seal.fill").font(.caption2).foregroundStyle(Theme.blue)
                                        }
                                        Label("\(person.distance) km away", systemImage: "location").font(.caption).foregroundStyle(.secondary)
                                    }.padding(12)
                                }.background(.white).clipShape(RoundedRectangle(cornerRadius: 20))
                                    .overlay(alignment: .topTrailing) {
                                        Image(systemName: category == .favorites ? "star.fill" : "heart.fill").font(.caption).foregroundStyle(category == .favorites ? .orange : .pink).padding(9).background(.white, in: Circle()).padding(10)
                                    }
                            }.buttonStyle(.plain).accessibilityIdentifier("connection-\(person.id)")
                        }
                    }.padding(.horizontal, 18).padding(.bottom, 24)
                }
            }
        }.background(Theme.canvas).toolbar(.hidden, for: .navigationBar)
            .sheet(item: $detail) { person in NavigationStack { PersonDetailView(person: person) } }
    }
}

struct ChatsView: View {
    @Environment(AppStore.self) private var store
    @State private var search = ""
    @State private var removePerson: Person?
    private var matches: [Person] { store.matches.filter { search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) } }
    var body: some View {
        VStack(spacing: 0) {
            BrandHeader(title: "Let the conversation flow.", subtitle: "A hello can change your whole day.")
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Search your connections", text: $search).accessibilityIdentifier("chat-search")
            }.padding(14).background(.white, in: RoundedRectangle(cornerRadius: 14)).padding(20)
            if matches.isEmpty {
                EmptyCard(icon: "bubble.left.and.bubble.right", title: "Your next hello is waiting.", message: "Match with someone in Discover to start a conversation.")
                Spacer()
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("YOUR CONNECTIONS").font(.caption.weight(.bold)).tracking(1.5).foregroundStyle(.secondary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 18) {
                            ForEach(matches) { person in
                                NavigationLink { ChatView(person: person) } label: {
                                    VStack(spacing: 7) {
                                        PersonAvatar(person: person, size: 60).overlay(Circle().stroke(Theme.cyan, lineWidth: 2))
                                        Text(person.name).font(.caption.weight(.medium)).foregroundStyle(Theme.ink)
                                    }
                                }.buttonStyle(.plain).accessibilityIdentifier("quick-chat-\(person.id)")
                            }
                        }.padding(.vertical, 3)
                    }
                }.padding(.horizontal, 22).padding(.bottom, 18)
                List {
                    Section {
                        ForEach(matches) { person in
                            NavigationLink { ChatView(person: person) } label: {
                                HStack(spacing: 13) {
                                    PersonAvatar(person: person, size: 58)
                                    VStack(alignment: .leading, spacing: 7) {
                                        HStack {
                                            Text(person.name).font(.headline)
                                            Spacer()
                                            if let last = store.messages(for: person).last { Text(last.date, style: .time).font(.caption2).foregroundStyle(.secondary) }
                                        }
                                        Text(store.messages(for: person).last?.text ?? "You matched. Say something lovely.").font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                                    }
                                    if (store.state.unread[person.id] ?? 0) > 0 {
                                        Circle().fill(Color.accentColor).frame(width: 9, height: 9)
                                    }
                                }.padding(.vertical, 8)
                            }.accessibilityIdentifier("chat-\(person.id)")
                                .swipeActions { Button("Unmatch", role: .destructive) { removePerson = person } }
                        }
                    } header: { Text("MESSAGES").font(.caption.weight(.bold)).tracking(1.5) }
                }.listStyle(.plain).scrollContentBackground(.hidden)
            }
        }.background(Theme.canvas).toolbar(.hidden, for: .navigationBar)
            .alert("Unmatch this connection?", isPresented: Binding(get: { removePerson != nil }, set: { if !$0 { removePerson = nil } })) {
                Button("Cancel", role: .cancel) { removePerson = nil }
                Button("Unmatch", role: .destructive) { if let person = removePerson { store.unmatch(person) }; removePerson = nil }
            } message: { Text("This removes the conversation from your local demo.") }
    }
}

struct ChatView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let person: Person
    @State private var draft = ""
    @State private var showProfile = false
    @State private var showReport = false
    @State private var showUnmatch = false
    @State private var showBlock = false
    private var messages: [ChatMessage] { store.messages(for: person) }
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 18) {
                    VStack(spacing: 8) {
                        PersonAvatar(person: person, size: 68)
                        Text("You connected with \(person.name)").font(.subheadline.weight(.semibold))
                        Text("Local demo · replies are simulated").font(.caption).foregroundStyle(.secondary)
                    }.padding(.vertical, 20)
                    ForEach(messages) { message in
                        HStack(alignment: .bottom, spacing: 8) {
                            if message.isMine { Spacer(minLength: 54) }
                            else { PersonAvatar(person: person, size: 27) }
                            VStack(alignment: message.isMine ? .trailing : .leading, spacing: 5) {
                                Text(message.text).font(.body).lineSpacing(3).padding(.horizontal, 16).padding(.vertical, 12)
                                    .foregroundStyle(message.isMine ? .white : Theme.ink)
                                    .background(message.isMine ? Color.accentColor : .white, in: RoundedRectangle(cornerRadius: 20))
                                Text(message.date, style: .time).font(.system(size: 10)).foregroundStyle(.secondary).padding(.horizontal, 5)
                            }
                            if !message.isMine { Spacer(minLength: 54) }
                        }.id(message.id)
                    }
                }.padding(.horizontal, 18).padding(.bottom, 20)
            }
            .background(Theme.canvas).scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                HStack(alignment: .bottom, spacing: 12) {
                    TextField("Write a message…", text: $draft, axis: .vertical).lineLimit(1...4).padding(13)
                        .background(Theme.canvas, in: RoundedRectangle(cornerRadius: 22)).accessibilityIdentifier("message-input")
                    Button(action: send) { Image(systemName: "paperplane.fill").font(.title3).frame(width: 44, height: 44) }
                        .buttonStyle(.borderedProminent).buttonBorderShape(.circle)
                        .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty).accessibilityLabel("Send message").accessibilityIdentifier("send-message")
                }.padding(.horizontal, 16).padding(.vertical, 10).background(.bar)
            }
            .onAppear { store.markRead(person); if let last = messages.last { proxy.scrollTo(last.id, anchor: .bottom) } }
            .onChange(of: messages.count) { _, _ in
                if let last = messages.last { withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo(last.id, anchor: .bottom) } }
            }
        }
        .navigationTitle(person.name).navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("View profile", systemImage: "person.crop.circle") { showProfile = true }
                    Button("Report profile", systemImage: "flag") { showReport = true }
                    Button("Unmatch", systemImage: "heart.slash", role: .destructive) { showUnmatch = true }
                    Button("Block profile", systemImage: "hand.raised", role: .destructive) { showBlock = true }
                } label: { Image(systemName: "ellipsis") }.accessibilityLabel("Conversation options")
            }
        }
        .sheet(isPresented: $showProfile) { NavigationStack { PersonDetailView(person: person) } }
        .sheet(isPresented: $showReport) { ReportView(person: person) }
        .alert("Unmatch \(person.name)?", isPresented: $showUnmatch) {
            Button("Cancel", role: .cancel) { }
            Button("Unmatch", role: .destructive) { store.unmatch(person); dismiss() }
        } message: { Text("Your conversation will be removed from this local demo.") }
        .alert("Block \(person.name)?", isPresented: $showBlock) {
            Button("Cancel", role: .cancel) { }
            Button("Block", role: .destructive) { store.block(person); dismiss() }
        } message: { Text("This profile will no longer appear. You can unblock it in Settings.") }
        .toolbar(.hidden, for: .tabBar)
    }
    private func send() { store.send(draft, to: person); draft = "" }
}

struct ReportView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let person: Person
    @State private var reason = "Spam or scam"
    @State private var details = ""
    var body: some View {
        NavigationStack {
            Form {
                Section("What’s the concern?") {
                    Picker("Reason", selection: $reason) { ForEach(["Spam or scam", "Inappropriate content", "Harassment", "Other"], id: \.self) { Text($0) } }
                    TextField("Additional details (optional)", text: $details, axis: .vertical).lineLimit(3...6)
                }
                Section {
                    Button("Save demo report") { store.report(person, reason: reason + (details.isEmpty ? "" : ": " + details)); dismiss() }
                } footer: { Text("This is a local demo. Reports are saved on your device and are not sent to a moderation team. You can also block this sample profile.") }
            }.navigationTitle("Report \(person.name)").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }
}
