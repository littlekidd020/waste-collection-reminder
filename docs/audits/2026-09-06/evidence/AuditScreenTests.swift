import XCTest

// Audit capture/inspection only; production app remains unchanged.
final class AuditScreenTests: XCTestCase {
    private let app = XCUIApplication()

    func testScreensAndAccessibility() throws {
        continueAfterFailure = false
        app.launch()
        if app.buttons["Get Started"].waitForExistence(timeout: 3) {
            capture("welcome")
            audit("welcome")
            app.buttons["Get Started"].tap()
            app.staticTexts["Auckland Council"].tap()
            capture("council")
            app.buttons["Continue"].tap()
            capture("address-empty")
            app.buttons["Set up manually"].tap()
            capture("manual")
            app.navigationBars.buttons["Save"].tap()
            app.buttons["Continue"].tap()
            capture("reminders")
            app.buttons["Finish Setup"].tap()
            let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
            let deny = springboard.buttons["Don’t Allow"]
            if deny.waitForExistence(timeout: 3) { deny.tap() }
            if app.buttons["Finish Setup"].waitForExistence(timeout: 2) {
                capture("reminders-after-denial")
                app.buttons["Finish Setup"].tap()
            }
        }
        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 8))
        for name in ["Today", "Schedule", "Info", "Settings"] {
            app.tabBars.buttons[name].tap()
            capture(name.lowercased())
            audit(name)
        }
        app.buttons["Change Location"].tap()
        capture("change-address")
        let manual = app.buttons["Set up manually"]
        if !manual.isHittable { app.swipeUp() }
        manual.tap()
        capture("manual-edit")
        app.navigationBars.buttons["Cancel"].tap()
        app.navigationBars.buttons["Cancel"].tap()
        app.terminate()
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 5))
        capture("relaunch")
    }

    private func capture(_ name: String) {
        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "audit-\(name)"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        let tree = XCTAttachment(string: app.debugDescription)
        tree.name = "tree-\(name)"
        tree.lifetime = .keepAlways
        add(tree)
    }

    private func audit(_ name: String) {
        do {
            try app.performAccessibilityAudit(for: [.contrast, .hitRegion, .sufficientElementDescription, .textClipped]) { issue in
                print("AUDIT_A11Y \(name): \(issue.auditType.rawValue) \(issue.compactDescription) element=\(String(describing: issue.element))")
                return true // Record every issue; capture run success is not an accessibility pass.
            }
        } catch {
            print("AUDIT_A11Y_ERROR \(name): \(error)")
        }
    }
}
