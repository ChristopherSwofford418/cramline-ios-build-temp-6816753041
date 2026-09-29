import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

final class ShieldActionExtension: ShieldActionDelegate {
  private let settingsStore = ManagedSettingsStore(named: .cramline)
  private let activityCenter = DeviceActivityCenter()
  private let sharedState = SharedScreenTimeState.shared

  override func handle(
    action: ShieldAction, for application: ApplicationToken,
    completionHandler: @escaping (ShieldActionResponse) -> Void
  ) {
    handle(action: action, completionHandler: completionHandler)
  }

  override func handle(
    action: ShieldAction, for webDomain: WebDomainToken,
    completionHandler: @escaping (ShieldActionResponse) -> Void
  ) {
    handle(action: action, completionHandler: completionHandler)
  }

  override func handle(
    action: ShieldAction, for category: ActivityCategoryToken,
    completionHandler: @escaping (ShieldActionResponse) -> Void
  ) {
    handle(action: action, completionHandler: completionHandler)
  }

  private func handle(
    action: ShieldAction, completionHandler: @escaping (ShieldActionResponse) -> Void
  ) {
    switch action {
    case .primaryButtonPressed:
      completionHandler(.close)
    case .secondaryButtonPressed:
      pauseImmediately()
      completionHandler(.close)
    @unknown default:
      completionHandler(.close)
    }
  }

  private func pauseImmediately(now: Date = Date()) {
    // Fail open first; scheduling a resume is a best-effort follow-up.
    settingsStore.clearAllSettings()
    guard var snapshot = sharedState.loadSession() else { return }
    let pauseUntil = min(now.addingTimeInterval(15 * 60), snapshot.plannedEnd)
    snapshot.pauseUntil = pauseUntil
    snapshot.state = "paused"
    try? sharedState.saveSession(snapshot)

    guard pauseUntil < snapshot.plannedEnd else { return }
    let name = DeviceActivityName.pauseResume(snapshot.sessionID)
    activityCenter.stopMonitoring([name])
    let calendar = Calendar.autoupdatingCurrent
    let schedule = DeviceActivitySchedule(
      intervalStart: calendar.dateComponents(in: calendar.timeZone, from: pauseUntil),
      intervalEnd: calendar.dateComponents(in: calendar.timeZone, from: snapshot.plannedEnd),
      repeats: false
    )
    try? activityCenter.startMonitoring(name, during: schedule)
  }
}
