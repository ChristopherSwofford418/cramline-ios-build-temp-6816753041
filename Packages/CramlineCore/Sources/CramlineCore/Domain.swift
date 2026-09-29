import Foundation

public enum CramlineValidationError: Error, Equatable, LocalizedError {
  case sprintLengthOutsideAllowedRange
  case invalidTimeZone
  case invalidStudyWindow
  case tooManyWindowsForDay
  case sessionEndNotAfterStart
  case invalidPlanningHours

  public var errorDescription: String? {
    switch self {
    case .sprintLengthOutsideAllowedRange:
      return "Choose a sprint between 14 and 90 days."
    case .invalidTimeZone:
      return "Choose a valid local time zone."
    case .invalidStudyWindow:
      return "Each study window needs at least one day and a valid duration."
    case .tooManyWindowsForDay:
      return "You can create up to three recurring study windows per day."
    case .sessionEndNotAfterStart:
      return "A study session must end after it starts."
    case .invalidPlanningHours:
      return "Desired weekly study time must be between 1 and 80 hours."
    }
  }
}

public enum BroadStudyDomain: String, Codable, CaseIterable, Sendable {
  case licensing
  case certification
  case board
  case admission
  case qualifying
  case other

  public var displayName: String {
    rawValue.prefix(1).uppercased() + rawValue.dropFirst()
  }
}

public struct Sprint: Codable, Equatable, Sendable, Identifiable {
  public let id: UUID
  public let startedAt: Date
  public var endDate: Date
  public var timeZoneIdentifier: String
  public var broadStudyDomain: BroadStudyDomain?
  public let createdAt: Date

  public init(
    id: UUID = UUID(),
    startedAt: Date,
    endDate: Date,
    timeZoneIdentifier: String,
    broadStudyDomain: BroadStudyDomain? = nil,
    createdAt: Date = Date(),
    calendar: Calendar = .current
  ) throws {
    guard TimeZone(identifier: timeZoneIdentifier) != nil else {
      throw CramlineValidationError.invalidTimeZone
    }
    var localCalendar = calendar
    localCalendar.timeZone = TimeZone(identifier: timeZoneIdentifier)!
    let start = localCalendar.startOfDay(for: startedAt)
    let end = localCalendar.startOfDay(for: endDate)
    let dayCount = localCalendar.dateComponents([.day], from: start, to: end).day ?? 0
    guard (14...90).contains(dayCount) else {
      throw CramlineValidationError.sprintLengthOutsideAllowedRange
    }
    self.id = id
    self.startedAt = startedAt
    self.endDate = endDate
    self.timeZoneIdentifier = timeZoneIdentifier
    self.broadStudyDomain = broadStudyDomain
    self.createdAt = createdAt
  }
}

public enum Weekday: Int, Codable, CaseIterable, Hashable, Sendable {
  case sunday = 1
  case monday
  case tuesday
  case wednesday
  case thursday
  case friday
  case saturday

  public var shortName: String {
    switch self {
    case .sunday: return "Sun"
    case .monday: return "Mon"
    case .tuesday: return "Tue"
    case .wednesday: return "Wed"
    case .thursday: return "Thu"
    case .friday: return "Fri"
    case .saturday: return "Sat"
    }
  }
}

public struct LocalClockTime: Codable, Equatable, Hashable, Sendable {
  public let hour: Int
  public let minute: Int

  public init(hour: Int, minute: Int) throws {
    guard (0...23).contains(hour), (0...59).contains(minute) else {
      throw CramlineValidationError.invalidStudyWindow
    }
    self.hour = hour
    self.minute = minute
  }

  public var minutesFromMidnight: Int { (hour * 60) + minute }
}

public struct StudyWindow: Codable, Equatable, Sendable, Identifiable {
  public let id: UUID
  public let sprintID: UUID
  public var recurrenceDays: Set<Weekday>
  public var localStart: LocalClockTime
  public var localEnd: LocalClockTime
  public var enabled: Bool
  public var label: String?

  public init(
    id: UUID = UUID(),
    sprintID: UUID,
    recurrenceDays: Set<Weekday>,
    localStart: LocalClockTime,
    localEnd: LocalClockTime,
    enabled: Bool = true,
    label: String? = nil
  ) throws {
    guard !recurrenceDays.isEmpty, localStart != localEnd else {
      throw CramlineValidationError.invalidStudyWindow
    }
    self.id = id
    self.sprintID = sprintID
    self.recurrenceDays = recurrenceDays
    self.localStart = localStart
    self.localEnd = localEnd
    self.enabled = enabled
    self.label = label?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
  }

  public var crossesMidnight: Bool {
    localEnd.minutesFromMidnight <= localStart.minutesFromMidnight
  }
}

public enum OneOffSessionStatus: String, Codable, Sendable {
  case planned
  case active
  case paused
  case ended
}

public struct OneOffSession: Codable, Equatable, Sendable, Identifiable {
  public let id: UUID
  public let sprintID: UUID
  public let startsAt: Date
  public let endsAt: Date
  public var status: OneOffSessionStatus

  public init(
    id: UUID = UUID(),
    sprintID: UUID,
    startsAt: Date,
    endsAt: Date,
    status: OneOffSessionStatus = .planned
  ) throws {
    guard endsAt > startsAt else { throw CramlineValidationError.sessionEndNotAfterStart }
    self.id = id
    self.sprintID = sprintID
    self.startsAt = startsAt
    self.endsAt = endsAt
    self.status = status
  }
}

public enum ShieldState: String, Codable, CaseIterable, Sendable {
  case scheduled
  case active
  case paused
  case authorizationNeeded
  case ended
  case unknown

  public var displayName: String {
    switch self {
    case .scheduled: return "Scheduled"
    case .active: return "Active"
    case .paused: return "Paused"
    case .authorizationNeeded: return "Cannot apply—authorization needed"
    case .ended: return "Ended"
    case .unknown: return "State unknown"
    }
  }
}

public enum SessionSource: String, Codable, Sendable {
  case recurring
  case oneOff
}

public enum LocalCheckIn: String, Codable, CaseIterable, Sendable {
  case stayedWithPlan
  case pausedForRealNeed
  case endedEarly

  public var displayName: String {
    switch self {
    case .stayedWithPlan: return "Stayed with plan"
    case .pausedForRealNeed: return "Paused for a real need"
    case .endedEarly: return "Ended early"
    }
  }
}

public struct SessionState: Codable, Equatable, Sendable, Identifiable {
  public let id: UUID
  public let source: SessionSource
  public let plannedStart: Date
  public let plannedEnd: Date
  public var state: ShieldState
  public var emergencyPauseUntil: Date?
  public var endedAt: Date?
  public var localCheckIn: LocalCheckIn?
  public var label: String?

  public init(
    id: UUID = UUID(),
    source: SessionSource,
    plannedStart: Date,
    plannedEnd: Date,
    state: ShieldState = .scheduled,
    emergencyPauseUntil: Date? = nil,
    endedAt: Date? = nil,
    localCheckIn: LocalCheckIn? = nil,
    label: String? = nil
  ) throws {
    guard plannedEnd > plannedStart else { throw CramlineValidationError.sessionEndNotAfterStart }
    self.id = id
    self.source = source
    self.plannedStart = plannedStart
    self.plannedEnd = plannedEnd
    self.state = state
    self.emergencyPauseUntil = emergencyPauseUntil
    self.endedAt = endedAt
    self.localCheckIn = localCheckIn
    self.label = label?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
  }
}

public struct LocalPlan: Codable, Equatable, Sendable, Identifiable {
  public enum Origin: String, Codable, Sendable { case rules, ai }
  public let id: UUID
  public let sprintID: UUID
  public var userVisiblePlan: String
  public let createdBy: Origin
  public let savedAt: Date

  public init(
    id: UUID = UUID(), sprintID: UUID, userVisiblePlan: String, createdBy: Origin,
    savedAt: Date = Date()
  ) {
    self.id = id
    self.sprintID = sprintID
    self.userVisiblePlan = userVisiblePlan
    self.createdBy = createdBy
    self.savedAt = savedAt
  }
}

public struct LocalReflection: Codable, Equatable, Sendable, Identifiable {
  public let id: UUID
  public let sessionID: UUID
  public var text: String?
  public var outcomeCategory: LocalCheckIn?
  public let createdAt: Date

  public init(
    id: UUID = UUID(), sessionID: UUID, text: String? = nil, outcomeCategory: LocalCheckIn? = nil,
    createdAt: Date = Date()
  ) {
    self.id = id
    self.sessionID = sessionID
    self.text = text?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    self.outcomeCategory = outcomeCategory
    self.createdAt = createdAt
  }
}

public struct PrivacySettings: Codable, Equatable, Sendable {
  public enum ConsentState: String, Codable, Sendable { case notAsked, enabled, disabled }
  public var telemetryConsent: ConsentState
  public var aiRequestConsentState: ConsentState
  public var localDataDeletionState: Bool

  public init(
    telemetryConsent: ConsentState = .notAsked,
    aiRequestConsentState: ConsentState = .notAsked,
    localDataDeletionState: Bool = false
  ) {
    self.telemetryConsent = telemetryConsent
    self.aiRequestConsentState = aiRequestConsentState
    self.localDataDeletionState = localDataDeletionState
  }
}

extension String {
  fileprivate var nilIfEmpty: String? { isEmpty ? nil : self }
}
