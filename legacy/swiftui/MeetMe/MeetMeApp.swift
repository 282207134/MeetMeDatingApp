import SwiftUI

@main
struct MeetMeApp: App {
    @State private var store = AppStore()
    var body: some Scene {
        WindowGroup {
            RootView().environment(store).tint(Color.accentColor).preferredColorScheme(.light)
        }
    }
}

struct RootView: View {
    @Environment(AppStore.self) private var store
    var body: some View {
        Group {
            if !store.state.signedIn { WelcomeView() }
            else if !store.state.profileComplete { ProfileSetupView() }
            else { MainTabs() }
        }
        .overlay(alignment: .bottom) {
            if let toast = store.toast { ToastOverlay(text: toast).transition(.move(edge: .bottom).combined(with: .opacity)).allowsHitTesting(false) }
        }
        .animation(.easeInOut(duration: 0.25), value: store.toast)
        .fullScreenCover(item: Binding(get: { store.newMatch }, set: { store.newMatch = $0 })) { person in
            MatchView(person: person)
        }
    }
}

struct MainTabs: View {
    @Environment(AppStore.self) private var store
    var body: some View {
        TabView(selection: Binding(get: { store.selectedTab }, set: { store.selectedTab = $0 })) {
            Tab("Discover", systemImage: "rectangle.on.rectangle.angled", value: 0) { NavigationStack { DiscoverView() } }
            Tab("Connections", systemImage: "heart.circle", value: 1) { NavigationStack { ConnectionsView() } }
            Tab("Chats", systemImage: "bubble.left.and.bubble.right", value: 2) { NavigationStack { ChatsView() } }.badge(store.unreadCount)
            Tab("Profile", systemImage: "person.crop.circle", value: 3) { NavigationStack { MyProfileView() } }
        }
    }
}
