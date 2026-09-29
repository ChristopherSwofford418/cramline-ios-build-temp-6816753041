import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

final class DeviceActivityMonitorExtension: DeviceActivityMonitor {
  private let settingsStore = ManagedSettingsStore(named: .cramline)
  private let sharedState = SharedScreenTimeState.shared

  override func intervalDidStart(for activity: DeviceActivityName) {
    super.intervalDidStart(for: activity)
    guard sharedState.loadSchedulePolicy()?.contains(Date()) == true else {
      settingsStore.clearAllSettings()
      _ = sharedState.markMonitorInactive(activity.rawValue)
      return
    }
    sharedState.markMonitorActive(activity.rawValue)

    if let session = sharedState.loadSession(),
      let pauseUntil = session.pauseUntil,
      pauseUntil > Date()
    {
      settingsStore.clearAllSettings()
      return
    }

    applyShield()
    let definition = sharedState.monitorDefinition(named: activity.rawValue)
    let currentPlannedEnd = definition.flatMap { plannedEnd(for: $0, now: Date()) }
    if var session = sharedState.loadSession(), session.state != "ended" {
      session.state = "active"
      session.pauseUntil = nil
      if let currentPlannedEnd {
        session.plannedEnd = max(session.plannedEnd, currentPlannedEnd)
      }
      try? sharedState.saveSession(session)
    } else if let definition, let currentPlannedEnd {
      try? sharedState.saveSession(
        SharedSessionSnapshot(
          sessionID: UUID(),
          plannedStart: Date(),
          plannedEnd: currentPlannedEnd,
          state: "active",
          label: definition.label
        ))
    }
  }

  override func intervalDidEnd(for activity: DeviceActivityName) {
    super.intervalDidEnd(for: activity)
    let anotherCramlineMonitorIsActive = sharedState.markMonitorInactive(activity.rawValue)
    if !anotherCramlineMonitorIsActive {
      settingsStore.clearAllSettings()
      if var session = sharedState.loadSession() {
        session.state = "ended"
        session.pauseUntil = nil
        try? sharedState.saveSession(session)
      }
    }
  }

  private func applyShield() {
    let selection = sharedState.loadSelection()
    settingsStore.shield.applications =
      selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
    settingsStore.shield.applicationCategories = nil
    settingsStore.shield.webDomains =
      selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
  }

  private func plannedEnd(for definition: SharedMonitorDefinition, now: Date) -> Date? {
    guard let identifier = sharedState.loadSchedulePolicy()?.timeZoneIdentifier,
      let timeZone = TimeZone(identifier: identifier)
    else { return nil }
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone
    var components = calendar.dateComponents([.year, .month, .day], from: now)
    components.hour = definition.endHour
    components.minute = definition.endMinute
    components.second = 0
    components.timeZone = timeZone
    guard var end = calendar.date(from: components) else { return nil }
    if definition.crossesMidnight || end <= now {
      end = calendar.date(byAdding: .day, value: 1, to: end) ?? end.addingTimeInterval(86_400)
    }
    return end
  }
}
