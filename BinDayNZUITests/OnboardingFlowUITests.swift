import XCTest

/// Run on a dedicated simulator with this app uninstalled first. No personal data is used.
final class OnboardingFlowUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_NZ"]
        app.launch()
    }

    func testConfirmedScheduleRecoveryEditingGuidesAndRelaunch() throws {
        XCTAssertTrue(app.buttons["Get Started"].waitForExistence(timeout: 10))
        capture("01-welcome")
        app.buttons["Get Started"].tap()
        XCTAssertTrue(app.buttons["Set up manually"].waitForExistence(timeout: 5))
        capture("02-optional-address")
        app.buttons["Set up manually"].tap()
        XCTAssertTrue(app.navigationBars["Your bin schedule"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.navigationBars["Your bin schedule"].buttons["Save"].isEnabled)
        capture("03-per-bin-editor")
        let confirmation = app.switches["These dates look right"]
        reveal(confirmation.switches.firstMatch)
        confirmation.switches.firstMatch.tap()
        XCTAssertEqual(confirmation.value as? String, "1")
        XCTAssertTrue(app.navigationBars["Your bin schedule"].buttons["Save"].isEnabled)
        app.navigationBars["Your bin schedule"].buttons["Save"].tap()
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.staticTexts["Set Up Reminders"].waitForExistence(timeout: 5))
        capture("04-reminders")
        reveal(app.buttons["finishSetup"])
        app.buttons["finishSetup"].tap()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allowNotifications = ProcessInfo.processInfo.environment["BINDAYNZ_TEST_ALLOW_NOTIFICATIONS"] == "1"
        let deny = springboard.buttons["Don’t Allow"]
        let alternateDeny = springboard.buttons["Don't Allow"]
        if allowNotifications {
            let allow = springboard.buttons["Allow"]
            XCTAssertTrue(allow.waitForExistence(timeout: 5))
            allow.tap()
        } else {
            if deny.waitForExistence(timeout: 3) { deny.tap() }
            else if alternateDeny.exists { alternateDeny.tap() }
        }
        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 15))
        if app.staticTexts["You're set"].waitForExistence(timeout: 5) {
            capture("05-setup-complete")
            app.buttons["Done"].firstMatch.tap()
        }
        capture("05-today")
        let reminderStatus = allowNotifications
            ? app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Reminders scheduled through")).firstMatch
            : app.staticTexts["Notifications are not allowed"]
        reveal(reminderStatus)
        XCTAssertTrue(reminderStatus.exists)
        capture("05-reminder-status")

        app.buttons["Schedule options"].tap()
        app.buttons["Change schedule"].tap()
        XCTAssertTrue(app.navigationBars["Change schedule"].waitForExistence(timeout: 5))
        app.buttons["Review bin schedule"].tap()
        XCTAssertTrue(app.navigationBars["Your bin schedule"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.navigationBars["Your bin schedule"].buttons["Save"].isEnabled)
        capture("06-edit-preserved-schedule")
        app.navigationBars["Your bin schedule"].buttons["Cancel"].tap()
        app.navigationBars["Change schedule"].buttons["Cancel"].tap()

        app.tabBars.buttons["Schedule"].tap()
        XCTAssertTrue(app.navigationBars["Schedule"].waitForExistence(timeout: 5))
        capture("07-schedule")
        app.tabBars.buttons["Info"].tap()
        capture("08-info")
        app.buttons.containing(.staticText, identifier: "Rubbish").firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Rubbish"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.webViews.firstMatch.exists)
        XCTAssertFalse(app.buttons["Load video"].exists)
        capture("08-rubbish-guide")
        app.navigationBars["Rubbish"].buttons["Done"].tap()
        app.buttons.containing(.staticText, identifier: "Recycling").firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Recycling"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.webViews.firstMatch.exists)
        capture("09-recycling-guide")
        app.navigationBars["Recycling"].buttons["Done"].tap()
        app.tabBars.buttons["Settings"].tap()
        capture("10-settings")
        reveal(app.buttons["Privacy and Help"])
        app.buttons["Privacy and Help"].tap()
        XCTAssertTrue(app.navigationBars["Privacy and Help"].waitForExistence(timeout: 5))
        capture("11-privacy-help")
        app.navigationBars["Privacy and Help"].buttons.element(boundBy: 0).tap()
        reveal(app.buttons["languagePicker"], upward: false)
        app.buttons["languagePicker"].tap()
        app.buttons["简体中文"].tap()
        XCTAssertTrue(app.tabBars.buttons.element(boundBy: 3).isSelected)
        capture("12-language-preserves-tab")
        app.buttons["languagePicker"].tap()
        app.buttons["English"].tap()
        app.terminate()
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["Get Started"].exists)
        capture("13-relaunch")
    }

    /// Invoke after the clean onboarding journey, with the desired simulator
    /// appearance and content size. This records the actual saved-profile UI.
    func testSavedScheduleVisualEvidence() throws {
        try requireSavedSchedule()
        capture("14-saved-today")
        app.tabBars.buttons["Schedule"].tap()
        XCTAssertTrue(app.navigationBars["Schedule"].waitForExistence(timeout: 5))
        capture("15-saved-schedule")
        let list = app.segmentedControls.buttons["List"]
        if list.exists {
            list.tap()
            capture("16-saved-schedule-list")
        }
        let collection = app.buttons.containing(.staticText, identifier: "Rubbish").firstMatch
        reveal(collection)
        collection.tap()
        XCTAssertTrue(app.navigationBars["Collection details"].waitForExistence(timeout: 5))
        capture("17-saved-day-detail")
    }

    func testSavedScheduleContrastAudit() throws {
        try auditSavedSchedule(.contrast)
    }

    func testVisibleReminderStatusContrastAudit() throws {
        try requireSavedSchedule()
        reveal(app.staticTexts["Notifications are not allowed"])
        capture("21-visible-reminder-status")
        try app.performAccessibilityAudit(for: .contrast)
        app.tabBars.buttons["Schedule"].tap()
        XCTAssertTrue(app.navigationBars["Schedule"].waitForExistence(timeout: 5))
        try app.performAccessibilityAudit(for: .contrast)
    }

    func testSavedScheduleFrequencyAndOneOffChangePersist() throws {
        try requireSavedSchedule()
        app.buttons["Schedule options"].tap()
        app.buttons["Change schedule"].tap()
        app.buttons["Review bin schedule"].tap()
        XCTAssertTrue(app.navigationBars["Your bin schedule"].waitForExistence(timeout: 5))
        let rubbishFrequency = app.buttons["Frequency, Weekly"].firstMatch
        reveal(rubbishFrequency)
        rubbishFrequency.tap()
        app.buttons["Fortnightly"].tap()
        let changes = app.buttons["One-off changes (0)"].firstMatch
        reveal(changes)
        changes.tap()
        XCTAssertTrue(app.navigationBars["One-off changes"].waitForExistence(timeout: 5))
        reveal(app.buttons["Add change"])
        app.buttons["Add change"].tap()
        XCTAssertTrue(app.buttons["Remove change"].waitForExistence(timeout: 5))
        capture("18-added-one-off-change")
        app.navigationBars["One-off changes"].buttons.element(boundBy: 0).tap()
        let confirmation = app.switches["These dates look right"]
        reveal(confirmation.switches.firstMatch)
        confirmation.switches.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Your bin schedule"].buttons["Save"].isEnabled)
        app.navigationBars["Your bin schedule"].buttons["Save"].tap()
        XCTAssertTrue(app.navigationBars["Change schedule"].buttons["Save"].isEnabled)
        app.navigationBars["Change schedule"].buttons["Save"].tap()
        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 10))
        app.terminate()
        app.launch()
        try requireSavedSchedule()
        app.buttons["Schedule options"].tap()
        app.buttons["Change schedule"].tap()
        app.buttons["Review bin schedule"].tap()
        XCTAssertTrue(app.navigationBars["Your bin schedule"].waitForExistence(timeout: 5))
        assertFrequency("Fortnightly", for: "Rubbish")
        reveal(app.buttons["One-off changes (1)"])
        XCTAssertTrue(app.buttons["One-off changes (1)"].exists)
        capture("19-persisted-rubbish-change")
        assertFrequency("Fortnightly", for: "Recycling")
        assertFrequency("Weekly", for: "Food Scraps")
        capture("20-preserved-other-bins")
        app.navigationBars["Your bin schedule"].buttons["Cancel"].tap()
        app.navigationBars["Change schedule"].buttons["Cancel"].tap()
    }

    func testSavedScheduleHitRegionAudit() throws {
        try auditSavedSchedule(.hitRegion)
    }

    func testSavedScheduleDescriptionAudit() throws {
        try auditSavedSchedule(.sufficientElementDescription)
    }

    func testSavedScheduleDynamicTypeAudit() throws {
        try auditSavedSchedule(.dynamicType)
    }

    func testSavedScheduleTextClippedAudit() throws {
        try auditSavedSchedule(.textClipped)
    }

    private func requireSavedSchedule() throws {
        guard app.tabBars.buttons["Today"].waitForExistence(timeout: 10) else {
            throw XCTSkip("Run the clean onboarding journey first to create its synthetic saved schedule.")
        }
    }

    private func auditSavedSchedule(_ type: XCUIAccessibilityAuditType) throws {
        try requireSavedSchedule()
        try app.performAccessibilityAudit(for: type)
        app.tabBars.buttons["Schedule"].tap()
        XCTAssertTrue(app.navigationBars["Schedule"].waitForExistence(timeout: 5))
        try app.performAccessibilityAudit(for: type)
    }

    private func assertFrequency(_ frequency: String, for bin: String) {
        let binToggle = app.switches[bin]
        reveal(binToggle)
        let menus = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Frequency, ")).allElementsBoundByIndex
        let nextMenu = menus.filter { $0.frame.minY >= binToggle.frame.maxY }
            .min { $0.frame.minY < $1.frame.minY }
        XCTAssertEqual(nextMenu?.label, "Frequency, \(frequency)", "The frequency immediately below \(bin) must be preserved.")
    }

    private func reveal(_ element: XCUIElement, upward: Bool = true) {
        for _ in 0..<24 {
            if element.isHittable { return }
            let scrollUp = element.exists && element.frame.height > 0
                ? element.frame.midY > app.frame.midY : upward
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: scrollUp ? 0.72 : 0.32))
            let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: scrollUp ? 0.42 : 0.62))
            start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)
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
