import XCTest

@testable import CramlineCore

final class DomainAndScheduleTests: XCTestCase {
  private let utc = TimeZone(secondsFromGMT: 0)!

  func testSprintRejectsThirteenAndNinetyOneDays() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = utc
    let start = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!

    XCTAssertThrowsError(
      try Sprint(
        startedAt: start, endDate: calendar.date(byAdding: .day, value: 13, to: start)!,
        timeZoneIdentifier: "UTC"))
    XCTAssertThrowsError(
      try Sprint(
        startedAt: start, endDate: calendar.date(byAdding: .day, value: 91, to: start)!,
        timeZoneIdentifier: "UTC"))
    XCTAssertNoThrow(
      try Sprint(
        startedAt: start, endDate: calendar.date(byAdding: .day, value: 14, to: start)!,
        timeZoneIdentifier: "UTC"))
    XCTAssertNoThrow(
      try Sprint(
        startedAt: start, endDate: calendar.date(byAdding: .day, value: 90, to: start)!,
        timeZoneIdentifier: "UTC"))
  }

  func testMoreThanThreeWindowsOnOneDayIsRejected() throws {
    let sprintID = UUID()
    let windows = try (0..<4).map { minute in
      try StudyWindow(
        sprintID: sprintID,
        recurrenceDays: [.monday],
        localStart: LocalClockTime(hour: 8 + minute, minute: 0),
        localEnd: LocalClockTime(hour: 9 + minute, minute: 0)
      )
    }
    XCTAssertThrowsError(try ScheduleEngine.validate(windows)) { error in
      XCTAssertEqual(error as? CramlineValidationError, .tooManyWindowsForDay)
    }
  }

  func testOccurrencePreservesWallClockAcrossDST() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "America/New_York")!
    let start = calendar.date(from: DateComponents(year: 2026, month: 3, day: 1, hour: 12))!
    let end = calendar.date(from: DateComponents(year: 2026, month: 3, day: 20, hour: 12))!
    let sprint = try Sprint(
      startedAt: start, endDate: end, timeZoneIdentifier: "America/New_York", calendar: calendar)
    let window = try StudyWindow(
      sprintID: sprint.id,
      recurrenceDays: [.sunday],
      localStart: LocalClockTime(hour: 10, minute: 0),
      localEnd: LocalClockTime(hour: 11, minute: 0)
    )
    let occurrences = try ScheduleEngine.upcomingOccurrences(
      windows: [window], sprint: sprint, from: start, through: end, calendar: calendar)
    XCTAssertGreaterThanOrEqual(occurrences.count, 2)
    for occurrence in occurrences {
      XCTAssertEqual(calendar.component(.hour, from: occurrence.startsAt), 10)
    }
  }

  func testEmergencyPauseIsImmediateAndCappedAtSessionEnd() throws {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let session = try SessionState(
      source: .oneOff, plannedStart: now, plannedEnd: now.addingTimeInterval(600), state: .active)
    let paused = SessionReducer.reduce(session, action: .pauseRequested(now: now, duration: 900))
    XCTAssertEqual(paused.state, .paused)
    XCTAssertEqual(paused.emergencyPauseUntil, session.plannedEnd)
  }

  func testEndedSessionCannotReactivate() throws {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    let session = try SessionState(
      source: .oneOff, plannedStart: now, plannedEnd: now.addingTimeInterval(3600), state: .active)
    let ended = SessionReducer.reduce(session, action: .ended(now: now, checkIn: .endedEarly))
    let attemptedRestart = SessionReducer.reduce(ended, action: .shieldApplied)
    XCTAssertEqual(attemptedRestart.state, .ended)
  }
}
