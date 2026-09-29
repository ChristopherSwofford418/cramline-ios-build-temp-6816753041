import Foundation

public struct StudyOccurrence: Equatable, Sendable, Identifiable {
  public let id: String
  public let windowID: UUID
  public let startsAt: Date
  public let endsAt: Date
  public let label: String?

  public init(windowID: UUID, startsAt: Date, endsAt: Date, label: String?) {
    self.windowID = windowID
    self.startsAt = startsAt
    self.endsAt = endsAt
    self.label = label
    self.id = "\(windowID.uuidString)-\(startsAt.timeIntervalSince1970)"
  }
}

public enum ScheduleEngine {
  public static func validate(_ windows: [StudyWindow]) throws {
    var countByDay: [Weekday: Int] = [:]
    for window in windows where window.enabled {
      guard !window.recurrenceDays.isEmpty else {
        throw CramlineValidationError.invalidStudyWindow
      }
      for day in window.recurrenceDays {
        countByDay[day, default: 0] += 1
        if countByDay[day, default: 0] > 3 {
          throw CramlineValidationError.tooManyWindowsForDay
        }
      }
    }
  }

  public static func upcomingOccurrences(
    windows: [StudyWindow],
    sprint: Sprint,
    from lowerBound: Date,
    through upperBound: Date,
    calendar baseCalendar: Calendar = .current
  ) throws -> [StudyOccurrence] {
    try validate(windows)
    guard upperBound >= lowerBound else { return [] }
    guard let timeZone = TimeZone(identifier: sprint.timeZoneIdentifier) else {
      throw CramlineValidationError.invalidTimeZone
    }

    var calendar = baseCalendar
    calendar.timeZone = timeZone
    let sprintStart = calendar.startOfDay(for: sprint.startedAt)
    let sprintEndExclusive = calendar.date(
      byAdding: .day, value: 1, to: calendar.startOfDay(for: sprint.endDate))!
    let effectiveStart = max(lowerBound, sprintStart)
    let effectiveEnd = min(upperBound, sprintEndExclusive)
    guard effectiveEnd >= effectiveStart else { return [] }

    var results: [StudyOccurrence] = []
    for window in windows where window.enabled {
      for weekday in window.recurrenceDays {
        var match = DateComponents()
        match.calendar = calendar
        match.timeZone = timeZone
        match.weekday = weekday.rawValue
        match.hour = window.localStart.hour
        match.minute = window.localStart.minute

        var cursor = effectiveStart.addingTimeInterval(-1)
        while let start = calendar.nextDate(
          after: cursor,
          matching: match,
          matchingPolicy: .nextTimePreservingSmallerComponents,
          repeatedTimePolicy: .first,
          direction: .forward
        ), start <= effectiveEnd {
          guard start < sprintEndExclusive else { break }
          let end = localEndDate(for: window, start: start, calendar: calendar)
          if end > effectiveStart, start <= effectiveEnd {
            results.append(
              StudyOccurrence(
                windowID: window.id, startsAt: start, endsAt: end, label: window.label))
          }
          cursor = start.addingTimeInterval(60)
        }
      }
    }

    return results.sorted {
      if $0.startsAt == $1.startsAt { return $0.endsAt < $1.endsAt }
      return $0.startsAt < $1.startsAt
    }
  }

  private static func localEndDate(for window: StudyWindow, start: Date, calendar: Calendar) -> Date
  {
    var day = calendar.dateComponents([.year, .month, .day], from: start)
    day.hour = window.localEnd.hour
    day.minute = window.localEnd.minute
    day.second = 0
    day.timeZone = calendar.timeZone
    var end = calendar.date(from: day) ?? start
    if window.crossesMidnight {
      end = calendar.date(byAdding: .day, value: 1, to: end) ?? end.addingTimeInterval(86_400)
    }
    if end <= start {
      end = start.addingTimeInterval(60)
    }
    return end
  }
}
