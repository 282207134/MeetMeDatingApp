import SwiftUI

struct DiscoverView: View {
    @Environment(AppStore.self) private var store
    @State private var showFilters = false
    @State private var detail: Person?
    @State private var drag: CGFloat = 0
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 18) {
                    BrandHeader(title: "A world of hellos.", subtitle: "Someone wonderful could be nearby.")
                    HStack {
                        Label("\(store.state.user.city) · Nearby", systemImage: "location.fill").font(.subheadline.weight(.medium))
                        Spacer()
                        Button { showFilters = true } label: { Label("Filters", systemImage: "slider.horizontal.3").font(.subheadline.weight(.semibold)) }.accessibilityIdentifier("discovery-filters")
                    }.padding(.horizontal, 24)
                    if let person = store.candidates.first {
                        VStack(spacing: 16) {
                            ZStack(alignment: .bottomLeading) {
                                Image(person.image).resizable().scaledToFill().frame(height: max(310, min(470, geometry.size.height - 260))).clipped()
                                LinearGradient(colors: [.clear, .clear, .black.opacity(0.75)], startPoint: .top, endPoint: .bottom)
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(spacing: 6) {
                                        Circle().fill(.green).frame(width: 7, height: 7)
                                        Text("Recently active").font(.caption.weight(.medium))
                                    }.padding(.horizontal, 10).padding(.vertical, 6).background(.ultraThinMaterial.opacity(0.8), in: Capsule())
                                    HStack(spacing: 8) {
                                        Text("\(person.name), \(person.age)").font(.system(size: 28, weight: .bold, design: .rounded))
                                        Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.cyan)
                                    }
                                    HStack(spacing: 14) {
                                        Label("\(person.distance) km away", systemImage: "location.fill")
                                        Label(person.job, systemImage: "briefcase.fill")
                                    }.font(.caption.weight(.medium))
                                }.foregroundStyle(.white).padding(22)
                                if abs(drag) > 35 {
                                    Text(drag > 0 ? "LIKE" : "PASS").font(.largeTitle.bold()).foregroundStyle(drag > 0 ? .green : .red)
                                        .padding(12).overlay(RoundedRectangle(cornerRadius: 8).stroke(lineWidth: 4)).rotationEffect(.degrees(drag > 0 ? -14 : 14)).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top).padding(.top, 32)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .offset(x: drag).rotationEffect(.degrees(Double(drag / 24)))
                            .onTapGesture { detail = person }
                            .gesture(DragGesture(minimumDistance: 20).onChanged { value in
                                if abs(value.translation.width) > abs(value.translation.height) { drag = value.translation.width }
                            }.onEnded { value in
                                if value.translation.width > 85 { store.like(person) }
                                else if value.translation.width < -85 { store.pass(person) }
                                withAnimation(.spring) { drag = 0 }
                            })
                            .accessibilityElement(children: .combine).accessibilityLabel("\(person.name), \(person.age), \(person.distance) kilometers away. Tap to view profile.")
                            .accessibilityAddTraits(.isButton).accessibilityAction { detail = person }.accessibilityIdentifier("discovery-card")
                            HStack(spacing: 22) {
                                action("Undo pass", icon: "arrow.uturn.backward", color: .orange, large: false) { store.undoPass() }
                                action("Pass", icon: "xmark", color: Theme.ink, large: true) { store.pass(person) }
                                action("Like", icon: "heart.fill", color: Color.accentColor, large: true) { store.like(person) }
                                action("Super like", icon: "star.fill", color: .purple, large: false) { store.like(person, superLike: true) }
                            }.padding(.bottom, 4)
                        }.padding(14).background(.white, in: RoundedRectangle(cornerRadius: 30))
                            .shadow(color: Theme.blue.opacity(0.06), radius: 18, y: 6).padding(.horizontal, 18)
                        Text("Swipe right to like, left to pass. Tap a card to know more.").font(.caption).foregroundStyle(.secondary).padding(.horizontal, 20)
                    } else {
                        VStack(spacing: 18) {
                            EmptyCard(icon: "sparkle.magnifyingglass", title: "You’re all caught up.", message: "Try widening your preferences, or revisit the profiles you’ve passed.")
                            PrimaryButton(title: "Adjust filters") { showFilters = true }
                            Button("Revisit passed profiles", action: store.resetDiscovery).font(.subheadline.weight(.semibold))
                        }.padding(24).padding(.top, 35)
                    }
                }.padding(.bottom, 24)
            }.background(Theme.canvas).toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showFilters) { FiltersView() }
            .sheet(item: $detail) { person in NavigationStack { PersonDetailView(person: person) } }
        }
    }
    private func action(_ label: String, icon: String, color: Color, large: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: large ? 26 : 20, weight: .semibold))
                .foregroundStyle(color).frame(width: large ? 66 : 48, height: large ? 66 : 48)
                .background(.white, in: Circle()).shadow(color: color.opacity(0.12), radius: 12, y: 5)
        }.buttonStyle(.plain).accessibilityLabel(label).accessibilityIdentifier("action-\(label.lowercased().replacingOccurrences(of: " ", with: "-"))")
    }
}

struct FiltersView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var filters = DiscoveryFilters()
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack { Label("Maximum distance", systemImage: "location"); Spacer(); Text("\(Int(filters.distance)) km").foregroundStyle(Theme.blue) }
                    Slider(value: $filters.distance, in: 1...100, step: 1).accessibilityIdentifier("distance-slider")
                } header: { Text("Close enough for a coffee") }
                Section("Age preferences") {
                    HStack { Text("Minimum age"); Spacer(); Text("\(Int(filters.minimumAge))").foregroundStyle(Theme.blue) }
                    Slider(value: $filters.minimumAge, in: 18...65, step: 1).onChange(of: filters.minimumAge) { _, value in if value > filters.maximumAge { filters.maximumAge = value } }
                    HStack { Text("Maximum age"); Spacer(); Text("\(Int(filters.maximumAge))").foregroundStyle(Theme.blue) }
                    Slider(value: $filters.maximumAge, in: 18...65, step: 1).onChange(of: filters.maximumAge) { _, value in if value < filters.minimumAge { filters.minimumAge = value } }
                }
                Section { Toggle("Verified profiles only", isOn: $filters.verifiedOnly) }
                Section {
                    Button("Reset preferences") { filters = DiscoveryFilters() }.accessibilityIdentifier("reset-filters")
                } footer: { Text("These preferences filter the local demo profiles. Your location is not collected.") }
            }.navigationTitle("Discovery filters").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button("Apply") { store.updateFilters(filters); dismiss() }.fontWeight(.semibold).accessibilityIdentifier("apply-filters") }
                }.onAppear { filters = store.state.filters }
        }
    }
}

struct PersonDetailView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let person: Person
    @State private var showReport = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Image(person.image).resizable().scaledToFill().frame(height: 420).clipped().clipShape(RoundedRectangle(cornerRadius: 26))
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("\(person.name), \(person.age)").font(.system(.largeTitle, design: .rounded, weight: .bold))
                        Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.blue)
                    }
                    Label("\(person.city) · \(person.distance) km away", systemImage: "location").foregroundStyle(.secondary)
                    Label(person.job, systemImage: "briefcase").foregroundStyle(.secondary)
                    Divider().padding(.vertical, 8)
                    Text("A little about me").font(.title3.bold())
                    Text(person.bio).foregroundStyle(.secondary).lineSpacing(5)
                    Text("We could talk about").font(.title3.bold()).padding(.top, 8)
                    InterestChips(items: person.interests)
                    HStack(spacing: 14) {
                        Button { store.toggleFavorite(person) } label: { Label(store.state.favorites.contains(person.id) ? "Saved" : "Save", systemImage: store.state.favorites.contains(person.id) ? "star.fill" : "star") }.buttonStyle(.bordered)
                        Spacer()
                        Button("Report profile") { showReport = true }.font(.caption).foregroundStyle(.secondary)
                    }.padding(.vertical)
                    if !store.state.matches.contains(person.id) {
                        PrimaryButton(title: "Like \(person.name)", icon: "heart.fill") { dismiss(); store.like(person) }.accessibilityIdentifier("detail-like")
                    }
                    Text("Sample profile · local demo").font(.caption2).foregroundStyle(.tertiary).frame(maxWidth: .infinity)
                }.padding(.horizontal, 6)
            }.padding(20)
        }.navigationTitle("Profile").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
            .sheet(isPresented: $showReport) { ReportView(person: person) }
    }
}

struct MatchView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let person: Person
    var body: some View {
        VStack(spacing: 26) {
            Spacer()
            Image("MeetMeMark").resizable().scaledToFit().frame(width: 70, height: 72)
            Text("It’s a match!").font(.system(size: 42, weight: .bold, design: .rounded)).accessibilityIdentifier("match-title")
            Text("You and \(person.name) liked each other.\nThis could be the start of something lovely.").multilineTextAlignment(.center).font(.subheadline).lineSpacing(5).opacity(0.9)
            HStack(spacing: -16) {
                MyAvatar(profile: store.state.user, size: 138).rotationEffect(.degrees(-9))
                PersonAvatar(person: person, size: 138).rotationEffect(.degrees(9))
            }.padding(.vertical, 20)
            Spacer()
            Button {
                store.selectedTab = 2; dismiss()
            } label: {
                Label("Say hello", systemImage: "bubble.left.fill").font(.headline).foregroundStyle(Theme.blue).frame(maxWidth: .infinity).padding(18).background(.white, in: RoundedRectangle(cornerRadius: 18))
            }.accessibilityIdentifier("match-say-hello")
            Button("Keep discovering") { dismiss() }.font(.headline).padding(12).accessibilityIdentifier("match-keep-discovering")
            Text("Demo match with a sample profile").font(.caption2).opacity(0.8).padding(.bottom, 18)
        }.foregroundStyle(.white).padding(28).frame(maxWidth: .infinity).background(Theme.gradient.ignoresSafeArea())
    }
}
