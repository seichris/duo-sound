import XCTest

final class ReleaseSmokeTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testPreviewLaunchAndPrivacy() throws {
        let app = XCUIApplication()
        app.launch()
        let status = app.staticTexts["monitoringStatus"]
        XCTAssertTrue(status.waitForExistence(timeout: 10))
        XCTAssertTrue(status.label.contains("SIMULATED HINGE"))
        capture("01-preview-home-not-hardware")
        app.buttons["About"].tap()
        let privacy = app.buttons["privacyPolicy"]
        XCTAssertTrue(privacy.waitForExistence(timeout: 5))
        privacy.tap()
        let summary = app.staticTexts["privacySummary"]
        XCTAssertTrue(summary.waitForExistence(timeout: 5))
        XCTAssertTrue(summary.label.contains("Device backups and deletion"))
        XCTAssertFalse(summary.label.contains("could not be loaded"))
        capture("02-privacy-summary")
    }

    @MainActor
    func testSimulatedOpenCloseDoesNotClaimHardware() throws {
        let app = XCUIApplication()
        app.launch()
        let open = app.buttons["demoOpen"]
        for _ in 0..<6 where !open.isHittable { app.swipeUp() }
        XCTAssertTrue(open.isHittable)
        open.tap()
        // Bring the actual status header back into view; don't fabricate state.
        for _ in 0..<6 where !app.staticTexts["lastEvent"].isHittable { app.swipeDown() }
        let event = app.staticTexts["lastEvent"]
        let opened = NSPredicate(format: "label CONTAINS %@", "Demo fold · Opening")
        expectation(for: opened, evaluatedWith: event)
        waitForExpectations(timeout: 5)
        XCTAssertTrue(app.staticTexts["monitoringStatus"].label.contains("SIMULATED HINGE"))
        capture("03-simulated-opening-not-hardware")
        let close = app.buttons["demoClose"]
        for _ in 0..<6 where !close.isHittable { app.swipeUp() }
        XCTAssertTrue(close.isHittable)
        close.tap()
        for _ in 0..<6 where !event.isHittable { app.swipeDown() }
        expectation(for: NSPredicate(format: "label CONTAINS %@", "Demo fold · Closing"), evaluatedWith: event)
        waitForExpectations(timeout: 5)
        capture("04-simulated-closing-not-hardware")
    }

    @MainActor
    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
