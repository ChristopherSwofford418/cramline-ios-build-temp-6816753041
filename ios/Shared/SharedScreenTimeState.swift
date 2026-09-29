import FamilyControls
import Foundation

public struct SharedSchedulePolicy: Codable, Equatable {
  public var sprintStartedAt: Date
  public var sprintEndDate: Date
  public var timeZoneIdentifier: String

  public init(sprintStartedAt: Date, sprintEndDate: Date, timeZoneIdentifier: String) {
    self.sprintStartedAt = sprintStartedAt
    self.sprintEndDate = sprintEndDate
    self.timeZoneIdentifier = timeZoneIdentifier
  }

  public func contains(_ date: Date) -> Bool {
    guard let timeZone = TimeZone(identifier: timeZoneIdentifier) else { return false }
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone
    let start = calendar.startOfDay(for: sprintStartedAt)
    let endExclusive = calendar.date(
      byAdding: .day, value: 1, to: calendar.startOfDay(for: sprintEndDate))!
    return date >= start && date < endExclusive
  }
}

public struct SharedMonitorDefinition: Codable, Equatable {
  public var name: String
  public var endHour: Int
  public var endMinute: Int
  public var crossesMidnight: Bool
  public var label: String?

  public init(name: String, endHour: Int, endMinute: Int, crossesMidnight: Bool, label: String?) {
    self.name = name
    self.endHour = endHour
    self.endMinute = endMinute
    self.crossesMidnight = crossesMidnight
    self.label = label
  }
}

public struct SharedSessionSnapshot: Codable, Equatable {
  public var sessionID: UUID
  public var plannedStart: Date
  public var plannedEnd: Date
  public var pauseUntil: Date?
  public var state: String
  public var label: String?

  public init(
    sessionID: UUID, plannedStart: Date, plannedEnd: Date, pauseUntil: Date? = nil, state: String,
    label: String? = nil
  ) {
    self.sessionID = sessionID
    self.plannedStart = plannedStart
    self.plannedEnd = plannedEnd
    self.pauseUntil = pauseUntil
    self.state = state
    self.label = label
  }
}

public final class SharedScreenTimeState {
  public static let shared = SharedScreenTimeState()

  private enum Key {
    static let selection = "screenTime.selection.v1"
    static let session = "screenTime.session.v2"
    static let schedulePolicy = "screenTime.schedulePolicy.v1"
    static let monitorDefinitions = "screenTime.monitorDefinitions.v1"
    static let activeMonitorNames = "screenTime.activeMonitorNames.v1"
  }

  private let defaults: UserDefaults
  private let encoder = JSONEncoder()
  private let decoder = JSONDecoder()

  public init(
    defaults: UserDefaults? = UserDefaults(suiteName: SharedIdentifiers.appGroupIdentifier)
  ) {
    self.defaults = defaults ?? .standard
  }

  public func saveSelection(_ selection: FamilyActivitySelection) throws {
    defaults.set(try encoder.encode(selection), forKey: Key.selection)
  }

  public func loadSelection() -> FamilyActivitySelection {
    guard let data = defaults.data(forKey: Key.selection),
      let selection = try? decoder.decode(FamilyActivitySelection.self, from: data)
    else {
      return FamilyActivitySelection()
    }
    return selection
  }

  public func saveSession(_ snapshot: SharedSessionSnapshot?) throws {
    guard let snapshot else {
      defaults.removeObject(forKey: Key.session)
      return
    }
    defaults.set(try encoder.encode(snapshot), forKey: Key.session)
  }

  public func loadSession() -> SharedSessionSnapshot? {
    guard let data = defaults.data(forKey: Key.session) else { return nil }
    return try? decoder.decode(SharedSessionSnapshot.self, from: data)
  }

  public func saveSchedulePolicy(_ policy: SharedSchedulePolicy) throws {
    defaults.set(try encoder.encode(policy), forKey: Key.schedulePolicy)
  }

  public func loadSchedulePolicy() -> SharedSchedulePolicy? {
    guard let data = defaults.data(forKey: Key.schedulePolicy) else { return nil }
    return try? decoder.decode(SharedSchedulePolicy.self, from: data)
  }

  public func saveMonitorDefinitions(_ definitions: [SharedMonitorDefinition]) throws {
    defaults.set(try encoder.encode(definitions), forKey: Key.monitorDefinitions)
  }

  public func monitorDefinition(named name: String) -> SharedMonitorDefinition? {
    guard let data = defaults.data(forKey: Key.monitorDefinitions),
      let definitions = try? decoder.decode([SharedMonitorDefinition].self, from: data)
    else { return nil }
    return definitions.first(where: { $0.name == name })
  }

  public func markMonitorActive(_ name: String) {
    var names = Set(defaults.stringArray(forKey: Key.activeMonitorNames) ?? [])
    names.insert(name)
    defaults.set(Array(names).sorted(), forKey: Key.activeMonitorNames)
  }

  @discardableResult
  public func markMonitorInactive(_ name: String) -> Bool {
    var names = Set(defaults.stringArray(forKey: Key.activeMonitorNames) ?? [])
    names.remove(name)
    defaults.set(Array(names).sorted(), forKey: Key.activeMonitorNames)
    return !names.isEmpty
  }

  public func clearActiveMonitors() {
    defaults.removeObject(forKey: Key.activeMonitorNames)
  }

  public func clearAll() {
    defaults.removeObject(forKey: Key.selection)
    defaults.removeObject(forKey: Key.session)
    defaults.removeObject(forKey: Key.schedulePolicy)
    defaults.removeObject(forKey: Key.monitorDefinitions)
    defaults.removeObject(forKey: Key.activeMonitorNames)
  }
}
