import Foundation
import Observation

struct Person: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let age: Int
    let city: String
    let distance: Int
    let job: String
    let image: String
    let bio: String
    let interests: [String]
    let likesYou: Bool
    var verified = true

    static let samples: [Person] = [
        .init(id: "cayla", name: "Cayla", age: 29, city: "Tokyo", distance: 2, job: "Designer", image: "PortraitCayla", bio: "Collecting little moments, good coffee, and places I haven’t been. Tell me about your favorite hidden gem.", interests: ["Travel", "Coffee", "Photography", "Hiking"], likesYou: true),
        .init(id: "sofia", name: "Sofia", age: 26, city: "Yokohama", distance: 6, job: "Photographer", image: "PortraitSofia", bio: "Usually by the ocean or looking for the best brunch spot. A good playlist makes everything better.", interests: ["Music", "Travel", "Art", "Food"], likesYou: false),
        .init(id: "emma", name: "Emma", age: 27, city: "Tokyo", distance: 4, job: "Editor", image: "PortraitAlex", bio: "Bookstores, slow Sundays, and conversations that make you forget to check your phone.", interests: ["Books", "Coffee", "Art", "Movies"], likesYou: true),
        .init(id: "noah", name: "Noah", age: 28, city: "Tokyo", distance: 8, job: "Architect", image: "AvatarMe", bio: "A little design, a little adventure. Always up for trying something new.", interests: ["Design", "Hiking", "Travel"], likesYou: true),
        .init(id: "maya", name: "Maya", age: 25, city: "Tokyo", distance: 12, job: "Illustrator", image: "PortraitCayla", bio: "Making things and making memories. Looking for a kind heart and a curious mind.", interests: ["Art", "Music", "Food"], likesYou: true)
    ]
}

struct ChatMessage: Identifiable, Codable, Hashable {
    var id = UUID().uuidString
    var text: String
    var isMine: Bool
    var date = Date()
}

struct UserProfile: Codable, Equatable {
    var name = "Alex"
    var age = 27
    var email = ""
    var city = "Tokyo"
    var job = "Product designer"
    var bio = "Curious about the world. Happiest with a good coffee, a new playlist, and a little adventure."
    var gender = "Man"
    var intention = "A meaningful connection"
    var interests = ["Travel", "Coffee", "Design"]
    var hasCustomPhoto = false
}

struct DiscoveryFilters: Codable, Equatable {
    var minimumAge = 18.0
    var maximumAge = 40.0
    var distance = 50.0
    var verifiedOnly = false
}

struct SavedState: Codable {
    var signedIn = false
    var profileComplete = false
    var user = UserProfile()
    var filters = DiscoveryFilters()
    var liked: [String] = []
    var passed: [String] = []
    var favorites: [String] = []
    var blocked: [String] = []
    var matches = ["emma", "noah"]
    var messages: [String: [ChatMessage]] = [
        "emma": [.init(text: "Hi Alex! Your coffee recommendation looks so good.", isMine: false), .init(text: "It’s my favorite little spot in Tokyo!", isMine: true), .init(text: "We should swap recommendations sometime.", isMine: false)],
        "noah": [.init(text: "Hey! Have you tried the hiking trail near Kamakura?", isMine: false)]
    ]
    var unread: [String: Int] = ["emma": 1, "noah": 1]
    var notifications = true
    var showOnline = true
    var premiumPreview = false
    var reports: [String] = []
}

@MainActor @Observable
final class AppStore {
    private(set) var state: SavedState { didSet { save() } }
    var selectedTab = 0
    var newMatch: Person?
    var toast: String?
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let storageKey = "meetme.local.state.v1"
    @ObservationIgnored private var toastTask: Task<Void, Never>?

    init(defaults: UserDefaults = .standard, arguments: [String] = ProcessInfo.processInfo.arguments) {
        self.defaults = defaults
        if arguments.contains("-ui-testing") { defaults.removeObject(forKey: storageKey) }
        if let data = defaults.data(forKey: storageKey), let saved = try? JSONDecoder().decode(SavedState.self, from: data) {
            state = saved
        } else { state = SavedState() }
        if arguments.contains("-demo") { state.signedIn = true; state.profileComplete = true }
    }

    var candidates: [Person] {
        Person.samples.filter { p in
            !state.liked.contains(p.id) && !state.passed.contains(p.id) && !state.blocked.contains(p.id) && !state.matches.contains(p.id)
            && p.age >= Int(state.filters.minimumAge) && p.age <= Int(state.filters.maximumAge)
            && p.distance <= Int(state.filters.distance) && (!state.filters.verifiedOnly || p.verified)
        }
    }
    var matches: [Person] { state.matches.compactMap(person).filter { !state.blocked.contains($0.id) } }
    var peopleWhoLikeYou: [Person] { Person.samples.filter { $0.likesYou && !state.matches.contains($0.id) && !state.blocked.contains($0.id) } }
    var unreadCount: Int { state.unread.values.reduce(0, +) }
    func person(_ id: String) -> Person? { Person.samples.first { $0.id == id } }

    func startDemo() { state.signedIn = true; state.profileComplete = true }
    func signIn(name: String, email: String, create: Bool) {
        if !name.trimmingCharacters(in: .whitespaces).isEmpty { state.user.name = name.trimmingCharacters(in: .whitespaces) }
        state.user.email = email
        state.signedIn = true
        if create { state.profileComplete = false }
    }
    func finishProfile(_ profile: UserProfile) { state.user = profile; state.profileComplete = true }
    func updateProfile(_ profile: UserProfile) { state.user = profile; showToast("Profile saved") }
    func updateFilters(_ filters: DiscoveryFilters) { state.filters = filters; showToast("Discovery preferences updated") }
    func setNotifications(_ value: Bool) { state.notifications = value }
    func setOnline(_ value: Bool) { state.showOnline = value }
    func setPremiumPreview(_ value: Bool) { state.premiumPreview = value }
    func signOut() { state.signedIn = false; selectedTab = 0 }

    func like(_ person: Person, superLike: Bool = false) {
        guard !state.blocked.contains(person.id) else { return }
        if !state.liked.contains(person.id) { state.liked.append(person.id) }
        state.passed.removeAll { $0 == person.id }
        if person.likesYou {
            if !state.matches.contains(person.id) { state.matches.append(person.id) }
            if state.messages[person.id] == nil {
                state.messages[person.id] = [.init(text: "You matched! Say hello to \(person.name).", isMine: false)]
                state.unread[person.id] = 1
            }
            newMatch = person
        } else { showToast(superLike ? "Super like sent to \(person.name)" : "You liked \(person.name)") }
    }
    func pass(_ person: Person) {
        if !state.passed.contains(person.id) { state.passed.append(person.id) }
        showToast("Passed · you can find them in Connections")
    }
    func undoPass() {
        guard let id = state.passed.popLast(), let p = person(id) else { showToast("No passes to undo yet"); return }
        showToast("\(p.name) is back in your discovery stack")
    }
    func resetDiscovery() { state.passed.removeAll(); state.liked.removeAll(); showToast("Discovery refreshed") }
    func toggleFavorite(_ person: Person) {
        if state.favorites.contains(person.id) { state.favorites.removeAll { $0 == person.id }; showToast("Removed from favorites") }
        else { state.favorites.append(person.id); showToast("Added to favorites") }
    }
    func markRead(_ person: Person) { state.unread[person.id] = 0 }
    func messages(for person: Person) -> [ChatMessage] { state.messages[person.id] ?? [] }
    func send(_ text: String, to person: Person) {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty, !state.blocked.contains(person.id), state.matches.contains(person.id) else { return }
        state.messages[person.id, default: []].append(.init(text: clean, isMine: true))
        Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(1100))
            guard let self, self.state.matches.contains(person.id), !self.state.blocked.contains(person.id) else { return }
            let reply = clean.lowercased().contains("coffee") ? "Coffee sounds lovely! What’s your favorite spot?" : "That sounds lovely! I’d like to hear more about it."
            self.state.messages[person.id, default: []].append(.init(text: reply, isMine: false))
        }
    }
    func unmatch(_ person: Person) {
        state.matches.removeAll { $0 == person.id }; state.messages.removeValue(forKey: person.id); state.unread.removeValue(forKey: person.id)
    }
    func block(_ person: Person) {
        if !state.blocked.contains(person.id) { state.blocked.append(person.id) }
        unmatch(person); showToast("\(person.name) has been blocked")
    }
    func report(_ person: Person, reason: String) {
        state.reports.append("\(person.id): \(reason)")
        showToast("Report saved on this device · demo only")
    }
    func unblockAll() { state.blocked.removeAll(); showToast("Blocked profiles cleared") }
    func unblock(_ person: Person) { state.blocked.removeAll { $0 == person.id }; showToast("Profile unblocked") }
    func resetLocalData() {
        state = SavedState(); selectedTab = 0
        try? FileManager.default.removeItem(at: Self.photoURL)
    }
    func showToast(_ text: String) {
        toastTask?.cancel(); toast = text
        toastTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(3))
            if !Task.isCancelled { self?.toast = nil }
        }
    }
    private func save() {
        if let data = try? JSONEncoder().encode(state) { defaults.set(data, forKey: storageKey) }
    }
    static var photoURL: URL { URL.documentsDirectory.appending(path: "meetme-profile-photo.jpg") }
}
