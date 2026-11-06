import XCTest

final class ReleaseSmokeTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testDuoPublicHingeProvidesSilentInitialReading() throws {
        guard ProcessInfo.processInfo.environment["HINGY_DUO_INTEGRATION"] == "1" else {
            throw XCTSkip("Requires the typed Duo scheme and a real Duo simulator hinge; run the Duo SDK workflow.")
        }
        let app = XCUIApplication()
        app.launch()
        let status = app.staticTexts["monitoringStatus"]
        XCTAssertTrue(status.waitForExistence(timeout: 15))
        expectation(for: NSPredicate(format: "label == %@", "FOREGROUND LISTENING"), evaluatedWith: status)
        waitForExpectations(timeout: 15)
        XCTAssertFalse(app.staticTexts["No hinge reading"].exists)
        XCTAssertEqual(app.staticTexts["lastEvent"].label, "No sound triggered yet")
        capture("00-public-duo-hinge-initial-reading-simulator")
    }

    @MainActor
    func testSetupOffersBothSoundShortcuts() throws {
        let app = XCUIApplication()
        app.launch()
        let setup = app.buttons["shortcutsHelp"]
        for _ in 0..<5 where !setup.isHittable { app.swipeUp() }
        XCTAssertTrue(setup.isHittable)
        setup.tap()

        XCTAssertTrue(app.navigationBars["Sounds in other apps"].waitForExistence(timeout: 10))
        for identifier in ["addOpeningShortcut", "addClosingShortcut"] {
            XCTAssertTrue(app.descendants(matching: .any).matching(identifier: identifier).firstMatch.exists)
        }
        let save = app.buttons["saveBothShortcuts"]
        for _ in 0..<4 where !save.isHittable { app.swipeUp() }
        XCTAssertTrue(save.isHittable)
    }

    @MainActor
    func testPreviewLaunchAndPrivacy() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.navigationBars["Hingy - Hinge Sounds"].waitForExistence(timeout: 10))
        let status = app.staticTexts["monitoringStatus"]
        XCTAssertTrue(status.waitForExistence(timeout: 10))
        XCTAssertFalse(status.label.isEmpty)
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
    func testSoundLibraryAuditionSelectionAndPersistence() throws {
        let app = XCUIApplication()
        app.launch()
        openLibrary(app, event: "opened")
        searchLibrary(app, for: "Chime", rowID: "select-opened-chime").tap()
        let crystal = searchLibrary(app, for: "Crystal", rowID: "select-opened-crystal")
        app.buttons["preview-opened-crystal"].tap()
        let feedback = app.staticTexts["libraryPreviewStatus"]
        for _ in 0..<4 where !feedback.isHittable { app.swipeDown() }
        expectation(for: NSPredicate(format: "label CONTAINS %@", "Preview · Opening · Crystal"), evaluatedWith: feedback)
        waitForExpectations(timeout: 5)
        XCTAssertEqual(crystal.value as? String, "Not selected", "Preview must not save a selection")
        crystal.tap()
        XCTAssertEqual(crystal.value as? String, "Selected")
        capture("05-crystal-library-not-hardware")
        dismissLibrarySearch(app)
        app.buttons["Done"].tap()
        XCTAssertEqual(app.buttons["soundChoice-opened"].value as? String, "Crystal")

        openLibrary(app, event: "closed")
        let laser = searchLibrary(app, for: "Laser", rowID: "select-closed-laser")
        laser.tap()
        dismissLibrarySearch(app)
        app.buttons["Done"].tap()
        XCTAssertEqual(app.buttons["soundChoice-closed"].value as? String, "Laser")
        app.terminate()
        app.launch()
        let closing = app.buttons["soundChoice-closed"]
        for _ in 0..<6 where !closing.isHittable { app.swipeUp() }
        XCTAssertEqual(closing.value as? String, "Laser")
        XCTAssertEqual(app.buttons["soundChoice-opened"].value as? String, "Crystal")
    }

    @MainActor
    func testRecordedSoundsAndOfflineCredits() throws {
        let app = XCUIApplication()
        app.launch()
        openLibrary(app, event: "opened")
        let fart = searchLibrary(app, for: "Tiny Fart", rowID: "select-opened-tinyFart")
        let selectionBeforePreview = try XCTUnwrap(fart.value as? String)
        app.buttons["preview-opened-tinyFart"].tap()
        let status = app.staticTexts["libraryPreviewStatus"]
        expectation(for: NSPredicate(format: "label CONTAINS %@", "Preview · Opening · Tiny Fart"), evaluatedWith: status)
        waitForExpectations(timeout: 20)
        XCTAssertEqual(fart.value as? String, selectionBeforePreview)
        fart.tap()
        capture("07-fart-library-preview")
        dismissLibrarySearch(app)
        app.buttons["Done"].tap()

        openLibrary(app, event: "closed")
        let woodKnock = searchLibrary(app, for: "Wood Knock", rowID: "select-closed-woodKnock")
        woodKnock.tap()
        expectation(for: NSPredicate(format: "value == %@", "Selected"), evaluatedWith: woodKnock)
        waitForExpectations(timeout: 5)
        dismissLibrarySearch(app)
        app.buttons["Done"].tap()
        XCTAssertEqual(app.buttons["soundChoice-closed"].value as? String, "Wood Knock")
        app.terminate()
        app.launch()
        let closing = app.buttons["soundChoice-closed"]
        reveal(closing, in: app)
        XCTAssertEqual(closing.value as? String, "Wood Knock")
        capture("08-kenney-selection-persisted")
        app.buttons["About"].tap()
        let credits = app.buttons["soundCredits"]
        for _ in 0..<6 where !credits.isHittable { app.swipeUp() }
        XCTAssertTrue(credits.waitForExistence(timeout: 5))
        credits.tap()
        let text = app.staticTexts["soundCreditsText"]
        XCTAssertTrue(text.waitForExistence(timeout: 5))
        XCTAssertTrue(text.label.contains("Kenney"))
        XCTAssertTrue(text.label.contains("CC0 1.0"))
        XCTAssertTrue(text.label.contains("Tiny Fart"))
        capture("09-offline-sound-credits")
    }

    @MainActor
    func testSelectedPreviewsRespondWithoutHingeOrAutomaticSounds() {
        let app = XCUIApplication()
        app.launch()
        let enabled = app.switches["Enable fold sounds"]
        setSwitch(enabled, to: false, in: app)
        for event in ["opened", "closed"] {
            let preview = app.buttons["preview-selected-\(event)"]
            reveal(preview, in: app)
            preview.tap()
            let lastEvent = app.staticTexts["lastEvent"]
            for _ in 0..<6 where !lastEvent.isHittable { app.swipeDown() }
            let feedback = "Preview · \(event == "opened" ? "Opening" : "Closing")"
            expectation(for: NSPredicate(format: "label CONTAINS %@", feedback), evaluatedWith: lastEvent)
            waitForExpectations(timeout: 5)
            XCTAssertFalse(app.alerts.firstMatch.exists)
        }
        setSwitch(enabled, to: true, in: app)
        capture("06-manual-previews-with-fold-sounds-paused")
    }

    @MainActor
    private func openLibrary(_ app: XCUIApplication, event: String) {
        let choice = app.buttons["soundChoice-\(event)"]
        reveal(choice, in: app)
        choice.tap()
        let title = event == "opened" ? "Opening sounds" : "Closing sounds"
        XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 5))
    }

    @MainActor
    private func reveal(_ row: XCUIElement, in app: XCUIApplication) {
        // On Duo's outer display, isHittable can be true while a row is
        // partially behind the navigation bar. Reveal the entire row first;
        // a full-page swipe can overshoot from below the screen to the header.
        let safeTop = app.frame.minY + 100
        let safeBottom = app.frame.maxY - 70
        for _ in 0..<12 {
            let frame = row.exists ? row.frame : .null
            if !frame.isEmpty && frame.minY >= safeTop && frame.maxY <= safeBottom && row.isHittable { break }
            let aboveHeader = !frame.isEmpty && frame.minY < safeTop
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: aboveHeader ? 0.4 : 0.7))
            let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: aboveHeader ? 0.65 : 0.45))
            start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)
        }
        XCTAssertTrue(row.isHittable)
        XCTAssertGreaterThanOrEqual(row.frame.minY, safeTop)
        XCTAssertLessThanOrEqual(row.frame.maxY, safeBottom)
    }

    @MainActor
    private func searchLibrary(_ app: XCUIApplication, for query: String, rowID: String) -> XCUIElement {
        let search = app.searchFields.firstMatch
        // Compact Duo sheets collapse searchable into a bottom Search button.
        // Open that native control before expecting the editable field.
        if !search.waitForExistence(timeout: 2) {
            let activateSearch = app.buttons["Search"]
            XCTAssertTrue(activateSearch.waitForExistence(timeout: 5))
            activateSearch.tap()
        }
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        if search.buttons["Clear text"].exists {
            search.buttons["Clear text"].tap()
            // Clearing can end editing on iPadOS 27; focus the field again.
            search.tap()
        }
        // Search activation animates independently of the sheet on iPadOS 27.
        // Wait for focus UI before typing, with one bounded retry of the tap.
        let focused = NSPredicate { _, _ in
            app.keyboards.firstMatch.exists || app.buttons["Cancel"].isHittable || app.buttons["close"].isHittable
        }
        if XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: focused, object: nil)], timeout: 3) != .completed {
            search.tap()
            XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: focused, object: nil)], timeout: 5), .completed)
        }
        search.typeText(query)
        expectation(for: NSPredicate(format: "value == %@", query), evaluatedWith: search)
        waitForExpectations(timeout: 10)
        // Submit first so the keyboard retracts before tapping a filtered row.
        search.typeText("\n")
        let result = app.buttons.matching(identifier: rowID).firstMatch
        let viewport = app.frame
        let visible = NSPredicate { _, _ in
            guard result.exists else { return false }
            let frame = result.frame
            return !frame.isEmpty && viewport.intersects(frame)
        }
        let outcome = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: visible, object: nil)], timeout: 20)
        if outcome != .completed { capture("missing-search-result-\(rowID)") }
        XCTAssertEqual(outcome, .completed, "Expected a visible row for \(query)")
        return result
    }

    @MainActor
    private func dismissLibrarySearch(_ app: XCUIApplication) {
        // Search replaces the sheet toolbar. Older supported iOS versions use
        // Cancel, while iOS 27 uses a trailing close control.
        let cancel = app.buttons["Cancel"]
        let close = app.buttons["close"]
        if cancel.exists && cancel.isHittable { cancel.tap() }
        else if close.waitForExistence(timeout: 2) { close.tap() }
        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 5))
    }

    @MainActor
    private func setSwitch(_ toggle: XCUIElement, to enabled: Bool, in app: XCUIApplication) {
        reveal(toggle, in: app)
        let value = enabled ? "1" : "0"
        guard toggle.value as? String != value else { return }
        let changed = NSPredicate(format: "value == %@", value)
        toggle.tap()
        if XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: changed, object: toggle)],
                          timeout: 2) == .completed { return }
        // SwiftUI can expose the whole Form row as the switch. Target the
        // center of the trailing control if tapping the row didn't toggle it.
        if toggle.value as? String != value {
            let trailing = toggle.coordinate(withNormalizedOffset: CGVector(dx: 1, dy: 0.5))
            trailing.withOffset(CGVector(dx: -min(48, toggle.frame.width / 2), dy: 0)).tap()
        }
        expectation(for: changed, evaluatedWith: toggle)
        waitForExpectations(timeout: 5)
    }

    @MainActor
    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
