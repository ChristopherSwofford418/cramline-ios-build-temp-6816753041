import XCTest

@testable import CramlineCore

final class PrivacyAndPlannerTests: XCTestCase {
  func testTelemetryAcceptsOnlyExactAllowlistedPayload() throws {
    let event = try TelemetryPolicy.sanitize(
      name: "emergency_action",
      properties: ["action": "pause_used"]
    )
    XCTAssertEqual(event.name, "emergency_action")
    XCTAssertEqual(event.properties, ["action": "pause_used"])
  }

  func testTelemetryRejectsFictionalSensitiveData() {
    XCTAssertThrowsError(
      try TelemetryPolicy.sanitize(
        name: "sprint_action",
        properties: [
          "action": "session_started",
          "selected_app": "FictionalSocial",
          "exact_schedule": "2026-09-27T20:00:00Z",
          "reflection": "I felt distracted",
        ]
      ))
  }

  func testTelemetryRejectsArbitraryOperationalErrorText() {
    XCTAssertThrowsError(
      try TelemetryPolicy.sanitize(
        name: "app_operational_error",
        properties: ["category": "Token for FictionalVideo failed at 10:30"]
      ))
  }

  func testRulePlannerWorksWithoutNetwork() throws {
    let request = try PlanningRequest(
      sprintEndDate: Date().addingTimeInterval(30 * 86_400),
      timeZoneIdentifier: "UTC",
      broadStudyDomain: .certification,
      desiredWeeklyHours: 7,
      preferredTimes: []
    )
    let draft = RuleBasedPlanner.makeDraft(from: request)
    XCTAssertTrue(draft.isDraft)
    XCTAssertFalse(draft.sessions.isEmpty)
    XCTAssertEqual(draft.sessions.reduce(0) { $0 + $1.durationMinutes }, 420)
  }

  func testAIRequestHasNoDeviceOrAppSelectionFields() throws {
    let encoded = try JSONEncoder().encode(
      AIPlanningRequest(
        sprintEndDate: "2026-12-01",
        broadStudyDomain: .licensing,
        desiredWeeklyHours: 8,
        preferredTimes: [],
        selfReportedConfidence: 3,
        consentAcknowledged: true
      ))
    let text = String(decoding: encoded, as: UTF8.self)
    for forbidden in ["token", "selectedApp", "device", "message", "browser", "reflection"] {
      XCTAssertFalse(text.localizedCaseInsensitiveContains(forbidden))
    }
  }
}
