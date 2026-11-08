import XCTest

/// Captures the App Store listing screenshots. Run on a simulator with the app uninstalled and the
/// status bar overridden (see docs/store-listing-1.2.md). Reminders are granted so Today shows the
/// scheduled state. Sample schedule: rubbish weekly, recycling and food scraps fortnightly on
/// alternate weeks. Attachments are exported from the result bundle with xcresulttool.
final class StoreScreenshotUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_NZ"]
        app.launch()
    }

    func testCaptureStoreScreenshots() throws {
        XCTAssertTrue(app.buttons["Get Started"].waitForExistence(timeout: 10))
        app.buttons["Get Started"].tap()
        XCTAssertTrue(app.buttons["Set up manually"].waitForExistence(timeout: 5))
        app.buttons["Set up manually"].tap()
        XCTAssertTrue(app.navigationBars["Your bin schedule"].waitForExistence(timeout: 5))

        // Editor screenshot: the intro, rubbish and the start of recycling.
        sleep(1)
        capture("03-schedule-editor")

        // Rubbish stays weekly and recycling fortnightly (the defaults); food scraps becomes
        // fortnightly on the other week.
        // The form is lazy, so the rows are found by position under the Food Scraps toggle.
        let foodScrapsToggle = app.switches["Food Scraps"]
        reveal(foodScrapsToggle)
        let foodScrapsFrequency = try XCTUnwrap(firstControl(below: foodScrapsToggle,
            in: app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Frequency, "))))
        reveal(foodScrapsFrequency)
        foodScrapsFrequency.tap()
        app.buttons["Fortnightly"].tap()
        let foodScrapsNextDate = try XCTUnwrap(firstControl(below: foodScrapsToggle, in: app.segmentedControls))
        reveal(foodScrapsNextDate)
        foodScrapsNextDate.buttons.element(boundBy: 1).tap()
        sleep(1)
        capture("03b-schedule-editor-food-scraps")

        let confirmation = app.switches["These dates look right"]
        reveal(confirmation.switches.firstMatch)
        confirmation.switches.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Your bin schedule"].buttons["Save"].isEnabled)
        app.navigationBars["Your bin schedule"].buttons["Save"].tap()
        chooseCouncil()
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.staticTexts["Set Up Reminders"].waitForExistence(timeout: 5))
        reveal(app.buttons["finishSetup"])
        app.buttons["finishSetup"].tap()

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allow = springboard.buttons["Allow"]
        XCTAssertTrue(allow.waitForExistence(timeout: 10), "The notification permission alert must appear")
        allow.tap()

        XCTAssertTrue(app.staticTexts["You're set"].waitForExistence(timeout: 15))
        sleep(1)
        capture("02-setup-complete")
        app.buttons["Done"].firstMatch.tap()

        XCTAssertTrue(tab("Today").waitForExistence(timeout: 10))
        let remindersOn = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", "Reminders on")).firstMatch
        XCTAssertTrue(remindersOn.waitForExistence(timeout: 20), "Reminders must be scheduled")
        sleep(1)
        capture("01-today")

        tab("Schedule").tap()
        let nextCollections = app.staticTexts["Next collections"]
        XCTAssertTrue(nextCollections.waitForExistence(timeout: 5))
        sleep(1)
        capture("04-schedule")
        reveal(nextCollections)
        // Bring the rows under the label into view as well.
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
            .withOffset(CGVector(dx: 0, dy: -max(0, nextCollections.frame.minY - app.frame.height * 0.2)))
        start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.3)
        sleep(1)
        capture("04b-schedule-next-collections")

        tab("Guide").tap()
        XCTAssertTrue(guideHeading("Rubbish").waitForExistence(timeout: 5))
        sleep(1)
        capture("06-guide")
        app.swipeLeft()
        let secondPage = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", "Recycling, page 2")).firstMatch
        XCTAssertTrue(secondPage.waitForExistence(timeout: 5), "Swiping left must turn to the second bin")
        sleep(1)
        capture("06b-guide-second-bin")

        tab("Today").tap()
        let settings = app.buttons["Settings"].firstMatch
        XCTAssertTrue(settings.waitForExistence(timeout: 5))
        settings.tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        sleep(1)
        capture("07-settings")
        app.navigationBars["Settings"].buttons["Done"].tap()
    }

    /// The large bin name heading a Guide page.
    private func guideHeading(_ bin: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label == %@ AND elementType != %d", bin, XCUIElement.ElementType.button.rawValue)).firstMatch
    }

    /// Continue needs a council; the manual flow picks Auckland Council through the picker's search.
    private func chooseCouncil(_ name: String = "Auckland Council") {
        let council = app.buttons["Council"].firstMatch
        reveal(council)
        council.tap()
        XCTAssertTrue(app.navigationBars["Choose your council"].waitForExistence(timeout: 5))
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("Auckland")
        let row = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", name)).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 5))
        XCTAssertEqual(council.value as? String, name)
    }

    /// iPhone uses a bottom tab bar; iPad shows the tabs in the top bar, outside any tab bar element.
    private func tab(_ name: String) -> XCUIElement {
        let bottom = app.tabBars.buttons[name]
        if bottom.exists { return bottom }
        let candidates = app.buttons.matching(identifier: name).allElementsBoundByIndex
        return candidates.first(where: { $0.isHittable }) ?? app.buttons[name].firstMatch
    }

    private func firstControl(below anchor: XCUIElement, in query: XCUIElementQuery) -> XCUIElement? {
        query.allElementsBoundByIndex
            .filter { $0.frame.minY >= anchor.frame.maxY }
            .min { $0.frame.minY < $1.frame.minY }
    }

    /// Scrolls so the control becomes hittable. Drags are anchored just below the frontmost
    /// navigation bar: on iPad the editor is a centred form sheet, so screen-relative swipes miss it.
    private func reveal(_ element: XCUIElement, upward: Bool = true) {
        let bar = app.navigationBars.allElementsBoundByIndex.last(where: { $0.isHittable && $0.frame.height > 0 })
        let origin = app.coordinate(withNormalizedOffset: .zero)
        for _ in 0..<24 {
            if element.isHittable { return }
            let scrollUp: Bool
            if let bar, element.exists, element.frame.height > 0 {
                scrollUp = element.frame.midY > bar.frame.maxY + 220
            } else if element.exists, element.frame.height > 0 {
                scrollUp = element.frame.midY > app.frame.midY
            } else {
                scrollUp = upward
            }
            let (from, to): (XCUICoordinate, XCUICoordinate)
            if let bar {
                let x = bar.frame.midX
                let near = origin.withOffset(CGVector(dx: x, dy: bar.frame.maxY + 80))
                let far = origin.withOffset(CGVector(dx: x, dy: bar.frame.maxY + 480))
                (from, to) = scrollUp ? (far, near) : (near, far)
            } else {
                from = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: scrollUp ? 0.72 : 0.32))
                to = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: scrollUp ? 0.42 : 0.62))
            }
            from.press(forDuration: 0.05, thenDragTo: to, withVelocity: .slow, thenHoldForDuration: 0.1)
        }
        capture("unreachable-control")
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = "unreachable-control-hierarchy"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
        XCTAssertTrue(element.isHittable, "Control must remain reachable: \(element)")
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
