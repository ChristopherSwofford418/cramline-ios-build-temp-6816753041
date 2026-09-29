import XCTest

@MainActor
final class CramlineUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
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
  }

  func testEmergencyActionsRequireClearConfirmationAndRemainFree() throws {
    let app = XCUIApplication()
    app.launchArguments = ["-ui-testing", "-seed-active-session"]
    app.launch()

    let pause = app.buttons["Emergency pause — 15 minutes"]
    XCTAssertTrue(pause.waitForExistence(timeout: 5))
    XCTAssertTrue(app.buttons["End today’s session"].exists)
    pause.tap()
    XCTAssertTrue(app.buttons["Pause shield for 15 minutes"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.buttons["Keep studying"].exists)
    app.buttons["Keep studying"].tap()
    app.buttons["End today’s session"].tap()
    XCTAssertTrue(app.buttons["End today’s session"].waitForExistence(timeout: 2))
    XCTAssertTrue(
      app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'free and has no penalty'"))
        .firstMatch.exists)
  }

  func testPlannerShowsOfflineDraftAndUnavailableAIBoundary() throws {
    let app = XCUIApplication()
    app.launchArguments = ["-ui-testing", "-seed-onboarded"]
    app.launch()
    app.tabBars.buttons["Plan"].tap()

    XCTAssertTrue(app.staticTexts["Shape a week you can repeat."].waitForExistence(timeout: 5))
    XCTAssertTrue(app.buttons["Save schedule changes"].exists)
    XCTAssertTrue(app.buttons["Draft on this device"].exists)
    app.swipeUp()
    app.swipeUp()
    XCTAssertTrue(
      app.staticTexts["AI planning unavailable in this build"].waitForExistence(timeout: 2))
    XCTAssertTrue(
      app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'sends nothing anywhere'"))
        .firstMatch.exists)
  }

  func testPrivacyScreenOffersTelemetryControlAndConfirmedDeletion() throws {
    let app = XCUIApplication()
    app.launchArguments = ["-ui-testing", "-seed-onboarded"]
    app.launch()
    app.tabBars.buttons["Privacy"].tap()

    XCTAssertTrue(
      app.switches["Share anonymous usage and crash information"].waitForExistence(timeout: 5))
    app.swipeUp()
    app.swipeUp()
    let delete = app.buttons["Delete all local Cramline Exam Sprint data"]
    XCTAssertTrue(delete.waitForExistence(timeout: 2))
    delete.tap()
    XCTAssertTrue(app.buttons["Delete all local data"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.buttons["Cancel"].exists)
  }

  func testPremiumScreenTruthfullyShowsUnavailableOfferAndFreeFoundation() throws {
    let app = XCUIApplication()
    app.launchArguments = ["-ui-testing", "-seed-onboarded"]
    app.launch()
    app.tabBars.buttons["Premium"].tap()

    XCTAssertTrue(app.staticTexts["Core focus stays free."].waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["No Premium offer in this build"].exists)
    XCTAssertTrue(app.staticTexts["No subscription offer is available in this build."].exists)
    XCTAssertFalse(app.buttons["Subscribe"].exists)
    XCTAssertFalse(app.buttons["Restore Purchases"].exists)
  }
}
