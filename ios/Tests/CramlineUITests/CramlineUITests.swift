import XCTest

@MainActor
final class CramlineUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  private func capture(_ name: String, in app: XCUIApplication) {
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }

  private func tapNavigationItem(_ label: String, in app: XCUIApplication) {
    let item = app.descendants(matching: .any).matching(identifier: label).firstMatch
    XCTAssertTrue(item.waitForExistence(timeout: 5), "Missing navigation item: \(label)")
    item.tap()
  }

  func testOnboardingStatesAdultAndNonGuaranteeBoundary() throws {
    let app = XCUIApplication()
    app.launchArguments = ["-ui-testing", "-reset-local-state"]
    app.launch()

    XCTAssertTrue(
      app.staticTexts["A self-directed focus barrier for professional exam study sprints."]
        .waitForExistence(timeout: 5))
    XCTAssertTrue(
      app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'not parental control'"))
        .firstMatch.exists)
    XCTAssertTrue(app.switches["I confirm I am 18 or older"].exists)
    XCTAssertTrue(app.buttons["Continue"].exists)
    XCTAssertFalse(app.buttons["Continue"].isEnabled)
    capture("01-onboarding-boundary", in: app)
  }

  func testOnboardingRevealsSprintStepAfterAgeConfirmation() throws {
    let app = XCUIApplication()
    app.launchArguments = ["-ui-testing", "-reset-local-state"]
    app.launch()

    let ageToggle = app.switches["I confirm I am 18 or older"]
    XCTAssertTrue(ageToggle.waitForExistence(timeout: 5))
    ageToggle.tap()
    app.buttons["Continue"].tap()
    XCTAssertTrue(app.staticTexts["Choose your study sprint"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.datePickers["Sprint end date"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.buttons["Back"].exists)
    capture("02-sprint-setup", in: app)
  }

  func testEmergencyActionsRequireClearConfirmationAndRemainFree() throws {
    let app = XCUIApplication()
    app.launchArguments = ["-ui-testing", "-seed-active-session"]
    app.launch()

    let pause = app.buttons["Emergency pause — 15 minutes"]
    XCTAssertTrue(pause.waitForExistence(timeout: 5))
    XCTAssertTrue(app.buttons["End today’s session"].exists)
    capture("03-active-focus-session", in: app)
    pause.tap()
    XCTAssertTrue(app.buttons["confirm-emergency-pause"].waitForExistence(timeout: 2))
    capture("04-emergency-control", in: app)
    app.terminate()

    let endApp = XCUIApplication()
    endApp.launchArguments = ["-ui-testing", "-seed-active-session"]
    endApp.launch()
    let endSession = endApp.buttons["End today’s session"]
    XCTAssertTrue(endSession.waitForExistence(timeout: 5))
    endSession.tap()
    XCTAssertTrue(endApp.buttons["confirm-end-session"].waitForExistence(timeout: 2))
  }

  func testPlannerShowsOfflineDraftAndUnavailableAIBoundary() throws {
    let app = XCUIApplication()
    app.launchArguments = ["-ui-testing", "-seed-onboarded"]
    app.launch()
    tapNavigationItem("Plan", in: app)

    XCTAssertTrue(app.staticTexts["Shape a week you can repeat."].waitForExistence(timeout: 5))
    XCTAssertTrue(app.buttons["Save schedule changes"].exists)
    XCTAssertTrue(app.buttons["Draft on this device"].exists)
    capture("05-plan-builder", in: app)
    app.swipeUp()
    app.swipeUp()
    XCTAssertTrue(
      app.staticTexts["AI planning unavailable in this build"].waitForExistence(timeout: 2))
    XCTAssertTrue(
      app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'sends nothing anywhere'"))
        .firstMatch.exists)
    capture("06-local-planning-boundary", in: app)
  }

  func testPrivacyScreenOffersTelemetryControlAndConfirmedDeletion() throws {
    let app = XCUIApplication()
    app.launchArguments = ["-ui-testing", "-seed-onboarded"]
    app.launch()
    tapNavigationItem("Privacy", in: app)

    XCTAssertTrue(
      app.switches["Share anonymous usage and crash information"].waitForExistence(timeout: 5))
    app.swipeUp()
    app.swipeUp()
    let delete = app.buttons["Delete all local Cramline Exam Sprint data"]
    XCTAssertTrue(delete.waitForExistence(timeout: 2))
    capture("07-privacy-controls", in: app)
    delete.tap()
    XCTAssertTrue(app.buttons["Delete all local data"].waitForExistence(timeout: 2))
    let cancel = app.buttons["Cancel"]
    if cancel.exists {
      cancel.tap()
    } else {
      app.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.05)).tap()
    }
    XCTAssertTrue(delete.waitForExistence(timeout: 2))
  }

  func testPremiumScreenTruthfullyShowsUnavailableOfferAndFreeFoundation() throws {
    let app = XCUIApplication()
    app.launchArguments = ["-ui-testing", "-seed-onboarded"]
    app.launch()
    tapNavigationItem("Premium", in: app)

    XCTAssertTrue(app.staticTexts["Core focus stays free."].waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["No Premium offer in this build"].exists)
    XCTAssertTrue(app.staticTexts["No subscription offer is available in this build."].exists)
    XCTAssertFalse(app.buttons["Subscribe"].exists)
    XCTAssertFalse(app.buttons["Restore Purchases"].exists)
    capture("08-premium-boundary", in: app)
  }
}
