import SwiftUI
import PhotosUI

struct MyProfileView: View {
    @Environment(AppStore.self) private var store
    @State private var edit = false
    @State private var filters = false
    @State private var premium = false
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                BrandHeader(title: "Your story, beautifully you.", subtitle: "A little more you. A little more connection.")
                VStack(spacing: 12) {
                    MyAvatar(profile: store.state.user, size: 108).shadow(color: Theme.blue.opacity(0.12), radius: 14)
                    HStack(spacing: 7) {
                        Text("\(store.state.user.name), \(store.state.user.age)").font(.system(.title, design: .rounded, weight: .bold)).accessibilityIdentifier("my-profile-name")
                        Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.blue)
                    }
                    Label(store.state.user.city, systemImage: "mappin.and.ellipse").font(.subheadline).foregroundStyle(.secondary)
                    Button { edit = true } label: { Label("Edit profile", systemImage: "pencil").font(.subheadline.weight(.semibold)) }
                        .buttonStyle(.bordered).buttonBorderShape(.capsule).accessibilityIdentifier("edit-profile")
                }
                HStack(spacing: 0) {
                    stat("Likes sent", value: store.state.liked.count)
                    stat("Connections", value: store.matches.count)
                    stat("Favorites", value: store.state.favorites.count)
                }.padding(.vertical, 18).background(.white, in: RoundedRectangle(cornerRadius: 22)).padding(.horizontal, 20)
                VStack(alignment: .leading, spacing: 14) {
                    Text("A little about you").font(.headline)
                    Text(store.state.user.bio).font(.subheadline).foregroundStyle(.secondary).lineSpacing(4)
                    InterestChips(items: store.state.user.interests)
                }.padding(20).background(.white, in: RoundedRectangle(cornerRadius: 22)).padding(.horizontal, 20)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    Button { filters = true } label: { menuTile("Preferences", subtitle: "Find your people", icon: "slider.horizontal.3", color: Theme.blue) }.buttonStyle(.plain)
                    NavigationLink { SettingsView() } label: { menuTile("Settings", subtitle: "Make it yours", icon: "gearshape", color: Color.accentColor) }.buttonStyle(.plain).accessibilityIdentifier("open-settings")
                    NavigationLink { HelpView() } label: { menuTile("Help center", subtitle: "We’ve got you", icon: "questionmark.circle", color: .purple) }.buttonStyle(.plain)
                    NavigationLink { AboutView() } label: { menuTile("About Meetme", subtitle: "Made for connection", icon: "info.circle", color: Theme.ink) }.buttonStyle(.plain)
                }.padding(.horizontal, 20)
                Button { premium = true } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "sparkles").font(.title2)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(store.state.premiumPreview ? "Meetme Plus · Demo preview" : "A little extra possibility.").font(.headline)
                            Text("Take a look at Meetme Plus").font(.caption).opacity(0.85)
                        }
                        Spacer(); Image(systemName: "chevron.right")
                    }.foregroundStyle(.white).padding(22).background(Theme.gradient, in: RoundedRectangle(cornerRadius: 22))
                }.buttonStyle(.plain).padding(.horizontal, 20)
                Text("LOCAL DEMO · ALL PROFILES ARE SAMPLES").font(.system(size: 10, weight: .medium)).tracking(1.2).foregroundStyle(.secondary).padding(.bottom, 24)
            }
        }.background(Theme.canvas).toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $edit) { EditProfileView(profile: store.state.user) }
            .sheet(isPresented: $filters) { FiltersView() }
            .sheet(isPresented: $premium) { PremiumView() }
    }
    private func stat(_ title: String, value: Int) -> some View {
        VStack(spacing: 5) { Text("\(value)").font(.system(.title2, design: .rounded, weight: .bold)).foregroundStyle(Theme.blue); Text(title).font(.caption).foregroundStyle(.secondary) }.frame(maxWidth: .infinity)
    }
    private func menuTile(_ title: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).font(.title2).foregroundStyle(color).padding(.bottom, 6)
            Text(title).font(.subheadline.weight(.bold))
            Text(subtitle).font(.caption).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(20).background(.white, in: RoundedRectangle(cornerRadius: 22))
    }
}

struct EditProfileView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State var profile: UserProfile
    @State private var photo: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var photoError: String?
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 10) {
                            if let photoData, let image = UIImage(data: photoData) {
                                Image(uiImage: image).resizable().scaledToFill().frame(width: 110, height: 110).clipShape(Circle())
                            } else { MyAvatar(profile: profile, size: 110) }
                            PhotosPicker("Choose a profile photo", selection: $photo, matching: .images).font(.subheadline.weight(.semibold))
                            if let photoError { Text(photoError).font(.caption).foregroundStyle(.red) }
                        }; Spacer()
                    }.listRowBackground(Color.clear)
                }
                Section("The essentials") {
                    TextField("First name", text: $profile.name).accessibilityIdentifier("profile-name")
                    Picker("Age", selection: $profile.age) { ForEach(18..<100) { Text("\($0)").tag($0) } }
                    TextField("City", text: $profile.city)
                    TextField("What do you do?", text: $profile.job)
                }
                Section("Your story") {
                    TextField("Tell people a little about yourself", text: $profile.bio, axis: .vertical).lineLimit(3...6).accessibilityIdentifier("profile-bio")
                    Picker("Looking for", selection: $profile.intention) { ForEach(["A meaningful connection", "A long-term relationship", "New friends", "Still figuring it out"], id: \.self) { Text($0) } }
                }
                Section("Your interests") { InterestPicker(selection: $profile.interests).padding(.vertical, 8) }
                Section { Text("Your profile is saved only on this device. Photos stay in the app’s local storage.").font(.caption).foregroundStyle(.secondary) }
            }.navigationTitle("Edit profile").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            if let photoData {
                                do { try photoData.write(to: AppStore.photoURL, options: .atomic); profile.hasCustomPhoto = true }
                                catch { photoError = "Couldn’t save this photo. Try another image."; return }
                            }
                            profile.name = profile.name.trimmingCharacters(in: .whitespaces)
                            store.updateProfile(profile); dismiss()
                        }.fontWeight(.semibold).disabled(profile.name.trimmingCharacters(in: .whitespaces).isEmpty).accessibilityIdentifier("save-profile")
                    }
                }
                .onChange(of: photo) { _, item in
                    Task {
                        guard let item else { return }
                        if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data), let jpeg = image.jpegData(compressionQuality: 0.8) { photoData = jpeg; photoError = nil }
                        else { photoError = "Couldn’t read this photo. Please choose another." }
                    }
                }
        }
    }
}

struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @State private var confirmSignOut = false
    @State private var confirmReset = false
    var body: some View {
        Form {
            Section("Your account") {
                LabeledContent("Name", value: store.state.user.name)
                LabeledContent("Email", value: store.state.user.email.isEmpty ? "Demo account" : store.state.user.email)
                NavigationLink("Blocked profiles (\(store.state.blocked.count))") { BlockedProfilesView() }
            }
            Section {
                Toggle("Demo notifications", isOn: Binding(get: { store.state.notifications }, set: { store.setNotifications($0) })).accessibilityIdentifier("notifications-toggle")
                Toggle("Show my online status", isOn: Binding(get: { store.state.showOnline }, set: { store.setOnline($0) }))
            } header: { Text("Preferences") } footer: { Text("These switches save your in-app preferences. This demo does not send push notifications or share an online status with a server.") }
            Section("More about Meetme") {
                NavigationLink("Help center") { HelpView() }
                NavigationLink("About & local data") { AboutView() }
            }
            Section {
                Button("Sign out", role: .destructive) { confirmSignOut = true }.accessibilityIdentifier("sign-out")
                Button("Reset all demo data", role: .destructive) { confirmReset = true }
            } footer: { Text("Signing out preserves your local profile and conversations. Resetting restores the original sample data and removes your profile photo.") }
        }.navigationTitle("Settings").navigationBarTitleDisplayMode(.inline)
            .alert("Sign out of this demo?", isPresented: $confirmSignOut) {
                Button("Cancel", role: .cancel) { }
                Button("Sign out", role: .destructive) { store.signOut() }
            }
            .alert("Reset all local data?", isPresented: $confirmReset) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) { store.resetLocalData() }
            } message: { Text("Your profile edits, messages, preferences, and chosen photo will be removed from this demo.") }
    }
}

struct BlockedProfilesView: View {
    @Environment(AppStore.self) private var store
    var body: some View {
        List {
            if store.state.blocked.isEmpty { ContentUnavailableView("No blocked profiles", systemImage: "hand.raised", description: Text("Profiles you block will appear here.")) }
            ForEach(store.state.blocked.compactMap(store.person)) { person in
                HStack { PersonAvatar(person: person, size: 44); Text(person.name); Spacer(); Button("Unblock") { store.unblock(person) }.buttonStyle(.bordered) }
            }
        }.navigationTitle("Blocked profiles").navigationBarTitleDisplayMode(.inline)
    }
}

struct HelpView: View {
    var body: some View {
        List {
            Section("A good place to start") {
                DisclosureGroup("How do I make a connection?") { Text("In Discover, swipe right or tap the heart to like someone. When a sample profile likes you back, you’ll see a match and can start a conversation.").font(.subheadline).foregroundStyle(.secondary).padding(.vertical, 8) }
                DisclosureGroup("Can I change my preferences?") { Text("Tap Filters in Discover to adjust age, distance, and verified profiles. Your choices are saved on this device.").font(.subheadline).foregroundStyle(.secondary).padding(.vertical, 8) }
                DisclosureGroup("Are these real people and messages?") { Text("This is an interactive local demonstration. All profiles are samples and incoming chat messages are simulated. Nothing is sent to another person.").font(.subheadline).foregroundStyle(.secondary).padding(.vertical, 8) }
                DisclosureGroup("Where is my data stored?") { Text("Your profile, conversations, and preferences stay in the app’s local storage. Reset all demo data in Settings to remove your changes.").font(.subheadline).foregroundStyle(.secondary).padding(.vertical, 8) }
            }
            Section("Comfort comes first") {
                Label("You decide who to connect with", systemImage: "heart")
                Label("Block or unmatch from any conversation", systemImage: "hand.raised")
                Text("Demo reports stay on your device and do not reach a moderation service.").font(.caption).foregroundStyle(.secondary)
            }
        }.navigationTitle("Help center").navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image("MeetMeMark").resizable().scaledToFit().frame(width: 100, height: 102)
                Text("Meetme").font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text("Swipe. Like. Connect.").foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 18) {
                    Text("Made for meaningful hellos.").font(.title2.bold())
                    Text("A native iPhone demonstration based on the MeetMe Dating App design. Discover sample profiles, explore connections, and try conversations at your own pace.").lineSpacing(5)
                    Divider()
                    Label("Everything stays local", systemImage: "iphone").font(.headline)
                    Text("No real authentication, location tracking, remote messages, payments, or moderation are connected. Your changes persist on this device until you reset the demo or remove the app.").font(.subheadline).foregroundStyle(.secondary).lineSpacing(4)
                    Text("Version 1.0 · Local demo").font(.caption).foregroundStyle(.secondary)
                }.padding(24).background(.white, in: RoundedRectangle(cornerRadius: 24))
            }.padding(24)
        }.background(Theme.canvas).navigationTitle("About Meetme").navigationBarTitleDisplayMode(.inline)
    }
}

struct PremiumView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan = "Monthly"
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "sparkles").font(.system(size: 52)).foregroundStyle(Theme.gradient).padding(.top, 24)
                    Text("More ways to say hello.").font(.system(.largeTitle, design: .rounded, weight: .bold)).multilineTextAlignment(.center)
                    Text("Meetme Plus").font(.title3.weight(.semibold)).foregroundStyle(Theme.blue)
                    VStack(alignment: .leading, spacing: 22) {
                        Label("See who likes you", systemImage: "heart.fill")
                        Label("Make a memorable first impression", systemImage: "star.fill")
                        Label("Explore more possibilities", systemImage: "sparkle.magnifyingglass")
                    }.font(.headline).frame(maxWidth: .infinity, alignment: .leading).padding(24).background(.white, in: RoundedRectangle(cornerRadius: 22))
                    Picker("Preview plan", selection: $selectedPlan) { Text("Monthly").tag("Monthly"); Text("Yearly").tag("Yearly") }.pickerStyle(.segmented)
                    Text("Plan preview only · no price or purchase").font(.caption).foregroundStyle(.secondary)
                    PrimaryButton(title: store.state.premiumPreview ? "End demo preview" : "Activate demo preview") {
                        store.setPremiumPreview(!store.state.premiumPreview); dismiss(); store.showToast("Demo preview updated · no purchase made")
                    }
                    Text("All demonstration features are already available. This screen previews the subscription experience and does not charge you.").font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center).lineSpacing(4)
                }.padding(24)
            }.background(Theme.canvas).navigationTitle("Meetme Plus").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
        }
    }
}
