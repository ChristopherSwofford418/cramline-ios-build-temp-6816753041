import Combine
import CramlineCore
import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

@MainActor
final class ScreenTimeCoordinator: ObservableObject {
  @Published var selection: FamilyActivitySelection
  @Published private(set) var authorizationStatus: AuthorizationStatus
  @Published private(set) var displayedState: ShieldState = .unknown
  @Published private(set) var convertedCategorySelection = false

  private let authorizationCenter: AuthorizationCenter
  private let activityCenter: DeviceActivityCenter
  private let settingsStore: ManagedSettingsStore
  private let sharedState: SharedScreenTimeState
  private let isUITesting: Bool

  init(
    authorizationCenter: AuthorizationCenter = .shared,
    activityCenter: DeviceActivityCenter = DeviceActivityCenter(),
    settingsStore: ManagedSettingsStore = ManagedSettingsStore(named: .cramline),
    sharedState: SharedScreenTimeState = .shared
  ) {
    let isUITesting = ProcessInfo.processInfo.arguments.contains("-ui-testing")
    self.authorizationCenter = authorizationCenter
    self.activityCenter = activityCenter
    self.settingsStore = settingsStore
    self.sharedState = sharedState
    self.isUITesting = isUITesting
    self.selection = Self.pickerSelection(from: sharedState.loadSelection())
    self.authorizationStatus = isUITesting ? .approved : authorizationCenter.authorizationStatus
    if !isUITesting { refreshAuthorizationState() }
  }

  var selectedApplicationCount: Int { selection.applicationTokens.count }
  var canSaveSelection: Bool {
    selectedApplicationCount <= AppEnvironment.maximumSelectedApplications
  }

  func prepareSelectionPicker() {
    convertedCategorySelection = false
    selection = Self.pickerSelection(from: selection)
  }

  func finalizeSelectionPicker() {
    let includedCategory = !selection.categoryTokens.isEmpty
    selection = Self.pickerSelection(from: selection)
    convertedCategorySelection = includedCategory
  }

  func requestIndividualAuthorization() async {
    do {
      try await authorizationCenter.requestAuthorization(for: .individual)
    } catch {
      // The UI reports the resulting authorization state without logging details.
    }
    refreshAuthorizationState()
  }

  func refreshAuthorizationState() {
    if isUITesting {
      authorizationStatus = .approved
      return
    }
    authorizationStatus = authorizationCenter.authorizationStatus
    switch authorizationStatus {
    case .approved:
      if displayedState == .authorizationNeeded { displayedState = .unknown }
    case .denied, .notDetermined:
      clearShield()
      stopCramlineMonitoring()
      sharedState.clearAll()
      selection = FamilyActivitySelection(includeEntireCategory: true)
      convertedCategorySelection = false
      displayedState = .authorizationNeeded
    @unknown default:
      displayedState = .unknown
    }
  }

  func persistSelection() throws {
    selection = Self.pickerSelection(from: selection)
    guard selectedApplicationCount <= AppEnvironment.maximumSelectedApplications else {
      throw ScreenTimeCoordinatorError.applicationLimitExceeded
    }
    try sharedState.saveSelection(selection)
  }

  func registerRecurringWindows(_ windows: [StudyWindow], sprint: Sprint) throws {
    guard authorizationCenter.authorizationStatus == .approved else {
      displayedState = .authorizationNeeded
      throw ScreenTimeCoordinatorError.authorizationRequired
    }
    try ScheduleEngine.validate(windows)
    guard let timeZone = TimeZone(identifier: sprint.timeZoneIdentifier) else {
      throw CramlineValidationError.invalidTimeZone
    }

    stopCramlineMonitoring()
    sharedState.clearActiveMonitors()
    try sharedState.saveSchedulePolicy(
      SharedSchedulePolicy(
        sprintStartedAt: sprint.startedAt,
        sprintEndDate: sprint.endDate,
        timeZoneIdentifier: sprint.timeZoneIdentifier
      ))
    do {
      var definitions: [SharedMonitorDefinition] = []
      for window in windows where window.enabled {
        for day in window.recurrenceDays {
          var start = DateComponents()
          start.timeZone = timeZone
          start.weekday = day.rawValue
          start.hour = window.localStart.hour
          start.minute = window.localStart.minute

          var end = DateComponents()
          end.timeZone = timeZone
          end.weekday = window.crossesMidnight ? nextWeekday(after: day).rawValue : day.rawValue
          end.hour = window.localEnd.hour
          end.minute = window.localEnd.minute

          let schedule = DeviceActivitySchedule(
            intervalStart: start, intervalEnd: end, repeats: true)
          let name = DeviceActivityName("cramline.window.\(window.id.uuidString).\(day.rawValue)")
          try activityCenter.startMonitoring(name, during: schedule)
          definitions.append(
            SharedMonitorDefinition(
              name: name.rawValue,
              endHour: window.localEnd.hour,
              endMinute: window.localEnd.minute,
              crossesMidnight: window.crossesMidnight,
              label: window.label
            ))
        }
      }
      try sharedState.saveMonitorDefinitions(definitions)
      displayedState = .scheduled
    } catch {
      stopCramlineMonitoring()
      sharedState.clearActiveMonitors()
      clearShield()
      displayedState = .unknown
      throw error
    }
  }

  func startOneOffSession(_ session: SessionState) throws {
    guard authorizationCenter.authorizationStatus == .approved else {
      displayedState = .authorizationNeeded
      throw ScreenTimeCoordinatorError.authorizationRequired
    }
    guard
      !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty
        || !selection.webDomainTokens.isEmpty
    else {
      throw ScreenTimeCoordinatorError.noSelection
    }

    try persistSelection()
    let calendar = Calendar.autoupdatingCurrent
    let startsAt = max(session.plannedStart, Date().addingTimeInterval(2))
    let schedule = DeviceActivitySchedule(
      intervalStart: calendar.dateComponents(in: calendar.timeZone, from: startsAt),
      intervalEnd: calendar.dateComponents(in: calendar.timeZone, from: session.plannedEnd),
      repeats: false
    )
    do {
      try activityCenter.startMonitoring(.oneOff(session.id), during: schedule)
      try sharedState.saveSession(
        SharedSessionSnapshot(
          sessionID: session.id,
          plannedStart: session.plannedStart,
          plannedEnd: session.plannedEnd,
          state: ShieldState.active.rawValue,
          label: session.label
        ))
      applyShield()
      displayedState = .active
    } catch {
      activityCenter.stopMonitoring([.oneOff(session.id)])
      try? sharedState.saveSession(nil)
      clearShield()
      displayedState = .unknown
      throw error
    }
  }

  func emergencyPause(for session: SessionState, now: Date = Date()) throws -> Date {
    let pauseUntil = min(now.addingTimeInterval(15 * 60), session.plannedEnd)
    if isUITesting {
      displayedState = .paused
      return pauseUntil
    }
    clearShield()
    try sharedState.saveSession(
      SharedSessionSnapshot(
        sessionID: session.id,
        plannedStart: session.plannedStart,
        plannedEnd: session.plannedEnd,
        pauseUntil: pauseUntil,
        state: ShieldState.paused.rawValue,
        label: session.label
      ))
    displayedState = .paused

    if pauseUntil < session.plannedEnd {
      let calendar = Calendar.autoupdatingCurrent
      let schedule = DeviceActivitySchedule(
        intervalStart: calendar.dateComponents(in: calendar.timeZone, from: pauseUntil),
        intervalEnd: calendar.dateComponents(in: calendar.timeZone, from: session.plannedEnd),
        repeats: false
      )
      try activityCenter.startMonitoring(.pauseResume(session.id), during: schedule)
    }
    return pauseUntil
  }

  func endCurrentSession() {
    if isUITesting {
      displayedState = .ended
      return
    }
    clearShield()
    if let sessionID = sharedState.loadSession()?.sessionID {
      activityCenter.stopMonitoring([.oneOff(sessionID), .pauseResume(sessionID)])
    }
    try? sharedState.saveSession(nil)
    displayedState = .ended
  }

  func refreshActiveShieldAfterSelectionChange() {
    guard displayedState == .active else { return }
    applyShield()
  }

  func deleteAllLocalControls() {
    if isUITesting {
      selection = FamilyActivitySelection(includeEntireCategory: true)
      convertedCategorySelection = false
      displayedState = .ended
      return
    }
    clearShield()
    stopCramlineMonitoring()
    sharedState.clearAll()
    selection = FamilyActivitySelection(includeEntireCategory: true)
    convertedCategorySelection = false
    displayedState = .ended
  }

  private func applyShield() {
    let current = sharedState.loadSelection()
    settingsStore.shield.applications =
      current.applicationTokens.isEmpty ? nil : current.applicationTokens
    settingsStore.shield.applicationCategories = nil
    settingsStore.shield.webDomains =
      current.webDomainTokens.isEmpty ? nil : current.webDomainTokens
  }

  private func clearShield() {
    settingsStore.clearAllSettings()
  }

  private func stopCramlineMonitoring() {
    let names = activityCenter.activities.filter { $0.rawValue.hasPrefix("cramline.") }
    if !names.isEmpty { activityCenter.stopMonitoring(names) }
  }

  private func nextWeekday(after weekday: Weekday) -> Weekday {
    Weekday(rawValue: weekday.rawValue == 7 ? 1 : weekday.rawValue + 1)!
  }

  private static func pickerSelection(
    from source: FamilyActivitySelection
  ) -> FamilyActivitySelection {
    // Expanding a category lets the system picker return its concrete app and website tokens.
    // Rebuilding without category tokens prevents a broad, dynamic category rule from being saved.
    var result = FamilyActivitySelection(includeEntireCategory: true)
    result.applicationTokens = source.applicationTokens
    result.webDomainTokens = source.webDomainTokens
    return result
  }
}

enum ScreenTimeCoordinatorError: LocalizedError {
  case authorizationRequired
  case applicationLimitExceeded
  case noSelection

  var errorDescription: String? {
    switch self {
    case .authorizationRequired:
      return
        "\(AppEnvironment.appName) can’t apply your study shield until Screen Time permission is enabled again."
    case .applicationLimitExceeded:
      return
        "Apple supports shielding no more than 50 individual app tokens at once. Remove at least one app in the system picker before saving."
    case .noSelection:
      return "Choose at least one individual app or website in the system picker."
    }
  }
}
