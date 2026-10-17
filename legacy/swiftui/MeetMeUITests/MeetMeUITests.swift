import XCTest

@MainActor
final class MeetMeUITests: XCTestCase {
    private var app: XCUIApplication!
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-demo"]
        app.launch()
    }
    private func tab(_ name: String) { app.tabBars.buttons[name].tap() }
    private func capture(_ name: String) {
        // The target is a separate process; allow its transition to finish before visual QA.
        Thread.sleep(forTimeInterval: 0.8)
        let attachment = XCTAttachment(screenshot: app.screenshot()); attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }

    func testLikeMatchConversationAndPersistence() {
        XCTAssertTrue(app.buttons["action-like"].waitForExistence(timeout: 10))
        capture("01-discover")
        app.buttons["action-like"].tap()
        XCTAssertTrue(app.staticTexts["match-title"].waitForExistence(timeout: 5))
        capture("02-match")
        app.buttons["match-say-hello"].tap()
        XCTAssertTrue(app.buttons["chat-cayla"].waitForExistence(timeout: 5))
        app.buttons["chat-cayla"].tap()
        let input = app.textFields["message-input"].exists ? app.textFields["message-input"] : app.textViews["message-input"]
        XCTAssertTrue(input.waitForExistence(timeout: 5)); input.tap(); input.typeText("Coffee tomorrow?")
        app.buttons["send-message"].tap()
        XCTAssertTrue(app.staticTexts["Coffee tomorrow?"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Coffee sounds lovely! What’s your favorite spot?"].waitForExistence(timeout: 8))
        capture("03-conversation")
        app.terminate(); app.launchArguments = ["-demo"]; app.launch()
        tab("Chats")
        app.buttons["chat-cayla"].tap()
        XCTAssertTrue(app.staticTexts["Coffee tomorrow?"].waitForExistence(timeout: 5))
    }

    func testFilterEmptyStateAndReset() {
        app.buttons["discovery-filters"].tap()
        let slider = app.sliders["distance-slider"]
        XCTAssertTrue(slider.waitForExistence(timeout: 5)); slider.adjust(toNormalizedSliderPosition: 0)
        app.buttons["apply-filters"].tap()
        XCTAssertTrue(app.staticTexts["You’re all caught up."].waitForExistence(timeout: 5))
        app.terminate(); app.launchArguments = ["-demo"]; app.launch()
        XCTAssertTrue(app.staticTexts["You’re all caught up."].waitForExistence(timeout: 10))
        app.buttons["discovery-filters"].tap()
        app.buttons["reset-filters"].tap()
        app.buttons["apply-filters"].tap()
        XCTAssertTrue(app.buttons["action-like"].waitForExistence(timeout: 5))
    }

    func testEditProfileAndPreferencePersistence() {
        tab("Profile")
        capture("04-profile")
        app.buttons["edit-profile"].tap()
        let field = app.textFields["profile-name"]
        XCTAssertTrue(field.waitForExistence(timeout: 5)); field.tap()
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: (field.value as? String ?? "").count))
        field.typeText("Jordan")
        app.buttons["save-profile"].tap()
        XCTAssertTrue(app.staticTexts["Jordan, 27"].waitForExistence(timeout: 5))
        app.swipeUp()
        app.buttons["open-settings"].tap()
        let toggle = app.switches["notifications-toggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)).tap()
        XCTAssertEqual(toggle.value as? String, "0")
        capture("05-settings")
        app.terminate(); app.launchArguments = ["-demo"]; app.launch(); tab("Profile")
        XCTAssertTrue(app.staticTexts["Jordan, 27"].waitForExistence(timeout: 5))
        app.swipeUp(); app.buttons["open-settings"].tap()
        XCTAssertEqual(app.switches["notifications-toggle"].value as? String, "0")
    }

    func testRegistrationAndOnboarding() {
        app.terminate(); app.launchArguments = ["-ui-testing"]; app.launch()
        XCTAssertTrue(app.buttons["create-account"].waitForExistence(timeout: 10))
        capture("06-welcome")
        app.buttons["create-account"].tap()
        app.textFields["auth-name"].tap(); app.textFields["auth-name"].typeText("Taylor")
        app.buttons["keyboard-done"].tap()
        app.textFields["auth-email"].tap(); app.textFields["auth-email"].typeText("taylor@example.com")
        app.buttons["keyboard-done"].tap()
        XCTAssertEqual(app.textFields["auth-name"].value as? String, "Taylor")
        XCTAssertEqual(app.textFields["auth-email"].value as? String, "taylor@example.com")
        app.secureTextFields["auth-password"].tap(); app.secureTextFields["auth-password"].typeText("demo123")
        app.buttons["keyboard-done"].tap()
        let adult = app.switches["adult-confirmation"]
        adult.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)).tap()
        XCTAssertEqual(adult.value as? String, "1")
        capture("09-registration-form")
        XCTAssertTrue(app.buttons["auth-submit"].isEnabled)
        app.buttons["auth-submit"].tap()
        XCTAssertTrue(app.buttons["setup-next"].waitForExistence(timeout: 5))
        app.buttons["setup-next"].tap(); app.buttons["setup-next"].tap()
        capture("07-profile-setup")
        app.buttons["setup-next"].tap()
        XCTAssertTrue(app.buttons["action-like"].waitForExistence(timeout: 5))
        tab("Profile")
        XCTAssertTrue(app.staticTexts["Taylor, 27"].waitForExistence(timeout: 5))
    }

    func testFavoritesAndConnections() {
        let card = app.descendants(matching: .any).matching(identifier: "discovery-card").firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 5)); card.tap()
        let save = app.buttons["Save"]
        if !save.isHittable { app.swipeUp() }
        XCTAssertTrue(save.waitForExistence(timeout: 5)); save.tap()
        app.buttons["Done"].tap()
        tab("Connections")
        app.segmentedControls.buttons["Favorites"].tap()
        XCTAssertTrue(app.buttons["connection-cayla"].waitForExistence(timeout: 5))
        capture("08-connections")
    }
}
