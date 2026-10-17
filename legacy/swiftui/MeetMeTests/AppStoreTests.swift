import XCTest
@testable import MeetMe

@MainActor
final class AppStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suite: String!
    override func setUp() async throws {
        suite = "meetme.tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)!
    }
    override func tearDown() async throws { defaults.removePersistentDomain(forName: suite) }

    func testMutualLikeCreatesOnePersistentMatch() {
        let store = AppStore(defaults: defaults, arguments: [])
        let cayla = store.person("cayla")!
        store.like(cayla)
        store.like(cayla)
        XCTAssertEqual(store.state.matches.filter { $0 == "cayla" }.count, 1)
        XCTAssertEqual(store.messages(for: cayla).count, 1)
        XCTAssertEqual(store.newMatch?.id, "cayla")
        let restored = AppStore(defaults: defaults, arguments: [])
        XCTAssertTrue(restored.state.matches.contains("cayla"))
        XCTAssertFalse(restored.candidates.contains(cayla))
    }

    func testFiltersAndPassUndoPersist() {
        let store = AppStore(defaults: defaults, arguments: [])
        var filters = DiscoveryFilters(); filters.distance = 1
        store.updateFilters(filters)
        XCTAssertTrue(store.candidates.isEmpty)
        store.updateFilters(DiscoveryFilters())
        let first = store.candidates.first!
        store.pass(first)
        XCTAssertFalse(store.candidates.contains(first))
        store.undoPass()
        XCTAssertTrue(store.candidates.contains(first))
        XCTAssertTrue(AppStore(defaults: defaults, arguments: []).state.passed.isEmpty)
    }

    func testWhitespaceMessagesAreNotSentAndBlockRemovesConversation() {
        let store = AppStore(defaults: defaults, arguments: [])
        let emma = store.person("emma")!
        let before = store.messages(for: emma).count
        store.send("   \n  ", to: emma)
        XCTAssertEqual(store.messages(for: emma).count, before)
        store.send("Coffee tomorrow?", to: emma)
        XCTAssertEqual(store.messages(for: emma).last?.text, "Coffee tomorrow?")
        store.block(emma)
        XCTAssertFalse(store.matches.contains(emma))
        XCTAssertTrue(store.messages(for: emma).isEmpty)
        XCTAssertNil(store.state.unread[emma.id])
        store.send("Should not be sent", to: emma)
        XCTAssertTrue(store.messages(for: emma).isEmpty)
    }

    func testProfileAndPreferencesSurviveRestartAndSignOut() {
        let store = AppStore(defaults: defaults, arguments: [])
        store.startDemo()
        var user = store.state.user; user.name = "Jordan"; user.bio = "A fresh story."
        store.updateProfile(user)
        store.setNotifications(false)
        store.signOut()
        let restored = AppStore(defaults: defaults, arguments: [])
        XCTAssertFalse(restored.state.signedIn)
        XCTAssertEqual(restored.state.user.name, "Jordan")
        XCTAssertEqual(restored.state.user.bio, "A fresh story.")
        XCTAssertFalse(restored.state.notifications)
    }
}
