import Foundation

public struct PreferredStudyTime: Codable, Equatable, Sendable {
  public let weekday: Weekday
  public let start: LocalClockTime
  public let maximumMinutes: Int

  public init(weekday: Weekday, start: LocalClockTime, maximumMinutes: Int = 90) {
    self.weekday = weekday
    self.start = start
    self.maximumMinutes = min(max(maximumMinutes, 25), 180)
  }
}

public struct PlanningRequest: Codable, Equatable, Sendable {
  public let sprintEndDate: Date
  public let timeZoneIdentifier: String
  public let broadStudyDomain: BroadStudyDomain?
  public let desiredWeeklyHours: Double
  public let preferredTimes: [PreferredStudyTime]
  public let selfReportedConfidence: Int?

  public init(
    sprintEndDate: Date,
    timeZoneIdentifier: String,
    broadStudyDomain: BroadStudyDomain?,
    desiredWeeklyHours: Double,
    preferredTimes: [PreferredStudyTime],
    selfReportedConfidence: Int? = nil
  ) throws {
    guard (1...80).contains(desiredWeeklyHours) else {
      throw CramlineValidationError.invalidPlanningHours
    }
    guard TimeZone(identifier: timeZoneIdentifier) != nil else {
      throw CramlineValidationError.invalidTimeZone
    }
    self.sprintEndDate = sprintEndDate
    self.timeZoneIdentifier = timeZoneIdentifier
    self.broadStudyDomain = broadStudyDomain
    self.desiredWeeklyHours = desiredWeeklyHours
    self.preferredTimes = preferredTimes
    self.selfReportedConfidence = selfReportedConfidence.map { min(max($0, 1), 5) }
  }
}

public struct DraftSession: Codable, Equatable, Sendable, Identifiable {
  public let id: UUID
  public let weekday: Weekday
  public let start: LocalClockTime
  public let durationMinutes: Int
  public let focusCue: String

  public init(
    id: UUID = UUID(), weekday: Weekday, start: LocalClockTime, durationMinutes: Int,
    focusCue: String
  ) {
    self.id = id
    self.weekday = weekday
    self.start = start
    self.durationMinutes = durationMinutes
    self.focusCue = focusCue
  }
}

public struct PlanningDraft: Codable, Equatable, Sendable {
  public let sessions: [DraftSession]
  public let breakCadence: String
  public let implementationIntention: String
  public let isDraft: Bool

  public init(
    sessions: [DraftSession], breakCadence: String, implementationIntention: String,
    isDraft: Bool = true
  ) {
    self.sessions = sessions
    self.breakCadence = breakCadence
    self.implementationIntention = implementationIntention
    self.isDraft = isDraft
  }
}

public enum RuleBasedPlanner {
  public static func makeDraft(from request: PlanningRequest) -> PlanningDraft {
    let slots = request.preferredTimes.isEmpty ? defaultSlots() : request.preferredTimes
    let targetMinutes = max(5, Int((request.desiredWeeklyHours * 60 / 5).rounded()) * 5)
    let sessionCount = min(max(Int(ceil(Double(targetMinutes) / 90.0)), 1), 21)
    let totalUnits = targetMinutes / 5
    let baseUnits = totalUnits / sessionCount
    let remainder = totalUnits % sessionCount

    var sessions: [DraftSession] = []
    for index in 0..<sessionCount {
      let slot = slots[index % slots.count]
      let extraUnit = index < remainder ? 1 : 0
      let distributedMinutes = (baseUnits + extraUnit) * 5
      let duration = min(max(distributedMinutes, 25), slot.maximumMinutes)
      sessions.append(
        DraftSession(
          weekday: slot.weekday,
          start: slot.start,
          durationMinutes: duration,
          focusCue: cue(for: request.broadStudyDomain)
        ))
    }
    sessions.sort { lhs, rhs in
      lhs.weekday.rawValue == rhs.weekday.rawValue
        ? lhs.start.minutesFromMidnight < rhs.start.minutesFromMidnight
        : lhs.weekday.rawValue < rhs.weekday.rawValue
    }

    let longestSession = sessions.map { $0.durationMinutes }.max() ?? 25
    let cadence =
      longestSession >= 75
      ? "Work for 50 minutes, then take a 10-minute break."
      : "Work for 25 minutes, then take a 5-minute break."

    return PlanningDraft(
      sessions: sessions,
      breakCadence: cadence,
      implementationIntention:
        "If I want to open social media, I will write down the thought and return to the next study step."
    )
  }

  private static func cue(for domain: BroadStudyDomain?) -> String {
    switch domain {
    case .admission: return "Complete one question set, then review explanations."
    case .board, .licensing: return "Review one topic, then answer practice questions."
    case .certification, .qualifying: return "Study one objective, then test recall."
    case .other, .none: return "Choose one concrete outcome before starting."
    }
  }

  private static func defaultSlots() -> [PreferredStudyTime] {
    let start = try! LocalClockTime(hour: 19, minute: 0)
    return [
      PreferredStudyTime(weekday: .monday, start: start),
      PreferredStudyTime(weekday: .wednesday, start: start),
      PreferredStudyTime(weekday: .saturday, start: try! LocalClockTime(hour: 10, minute: 0)),
    ]
  }
}
