import Combine
import CramlineCore
import FamilyControls
import Foundation

struct StudyWindowInput {
  let id: UUID
  let recurrenceDays: Set<Weekday>
  let localStartDate: Date
  let durationMinutes: Int
}

@MainActor
final class AppModel: ObservableObject {
  @Published private(set) var persisted = PersistedAppState.empty
  @Published private(set) var isLoaded = false
  @Published var alertMessage: String?
  @Published var latestDraft: PlanningDraft?
  @Published private(set) var latestDraftOrigin: LocalPlan.Origin = .rules
  @Published var isRequestingAI = false

  let screenTime = ScreenTimeCoordinator()
  let purchases = PurchaseController()
  let telemetry = TelemetryController.shared

  private let repository = LocalRepository()
  private let aiClient = AIPlannerClient()

  init() {
    Task { await load() }
  }

  var currentSession: SessionState? {
    persisted.sessions.last(where: { $0.endedAt == nil && $0.state != .ended })
  }

  var activeSprint: Sprint? { persisted.sprint }

  var nextOccurrence: StudyOccurrence? {
    guard let sprint = persisted.sprint else { return nil }
    return try? ScheduleEngine.upcomingOccurrences(
      windows: persisted.windows,
      sprint: sprint,
      from: Date(),
      through: min(sprint.endDate, Date().addingTimeInterval(14 * 86_400))
    ).first
  }

  func load() async {
    let arguments = ProcessInfo.processInfo.arguments
    if arguments.contains("-reset-local-state") {
      try? await repository.deleteAll()
    }
    persisted = await repository.load()
    if arguments.contains("-seed-onboarded") || arguments.contains("-seed-active-session") {
      persisted = makeUITestState(activeSession: arguments.contains("-seed-active-session"))
    }
    telemetry.bootstrap(consent: persisted.privacy.telemetryConsent)
    screenTime.refreshAuthorizationState()
    isLoaded = true
  }

  func applicationDidBecomeActive() async {
    screenTime.refreshAuthorizationState()
    guard screenTime.authorizationStatus == .approved else {
      if let index = persisted.sessions.lastIndex(where: { $0.endedAt == nil }) {
        persisted.sessions[index].state = .authorizationNeeded
        try? await save()
      }
      return
    }
    guard let shared = SharedScreenTimeState.shared.loadSession(),
      let sharedState = ShieldState(rawValue: shared.state)
    else {
      if let index = persisted.sessions.lastIndex(where: {
        $0.endedAt == nil && $0.plannedEnd <= Date()
      }) {
        screenTime.endCurrentSession()
        persisted.sessions[index].state = .ended
        persisted.sessions[index].endedAt = Date()
        try? await save()
      }
      return
    }
    if let index = persisted.sessions.firstIndex(where: { $0.id == shared.sessionID }) {
      persisted.sessions[index].state = sharedState
      persisted.sessions[index].emergencyPauseUntil = shared.pauseUntil
      if sharedState == .ended {
        persisted.sessions[index].endedAt = Date()
      }
    } else if let session = try? SessionState(
      id: shared.sessionID,
      source: .recurring,
      plannedStart: shared.plannedStart,
      plannedEnd: shared.plannedEnd,
      state: sharedState,
      emergencyPauseUntil: shared.pauseUntil,
      label: shared.label
    ) {
      if sharedState != .ended { persisted.sessions.append(session) }
    }
    try? await save()
  }

  func completeOnboarding(
    endDate: Date, domain: BroadStudyDomain, startHour: Int, startMinute: Int, durationMinutes: Int
  ) async {
    do {
      let now = Date()
      let sprint = try Sprint(
        startedAt: now,
        endDate: endDate,
        timeZoneIdentifier: TimeZone.autoupdatingCurrent.identifier,
        broadStudyDomain: domain
      )
      let start = try LocalClockTime(hour: startHour, minute: startMinute)
      let total = start.minutesFromMidnight + durationMinutes
      let end = try LocalClockTime(hour: (total / 60) % 24, minute: total % 60)
      let window = try StudyWindow(
        sprintID: sprint.id,
        recurrenceDays: Set(Weekday.allCases),
        localStart: start,
        localEnd: end,
        label: "Study session"
      )
      try screenTime.persistSelection()
      try screenTime.registerRecurringWindows([window], sprint: sprint)
      persisted.sprint = sprint
      persisted.windows = [window]
      persisted.onboardingComplete = true
      try await save()
      telemetry.track(.onboardingCompleted, properties: ["entry": "rules_planner"])
      telemetry.track(.sprintAction, properties: ["action": "sprint_created"])
      telemetry.track(.sprintAction, properties: ["action": "schedule_created"])
    } catch {
      screenTime.deleteAllLocalControls()
      persisted = .empty
      alertMessage = error.localizedDescription
    }
  }

  func startOneOff(minutes: Int = 50) async {
    guard let sprint = persisted.sprint else { return }
    guard sprint.endDate >= Calendar.autoupdatingCurrent.startOfDay(for: Date()) else {
      alertMessage =
        "Your exam sprint has ended. Update the sprint before starting another session."
      return
    }
    do {
      let now = Date()
      let session = try SessionState(
        source: .oneOff,
        plannedStart: now,
        plannedEnd: now.addingTimeInterval(TimeInterval(minutes * 60)),
        state: .active,
        label: "Focused study"
      )
      try screenTime.startOneOffSession(session)
      persisted.sessions.append(session)
      try await save()
      telemetry.track(.sprintAction, properties: ["action": "session_started"])
    } catch {
      alertMessage = error.localizedDescription
    }
  }

  func updateSprintAndWindows(endDate: Date, inputs: [StudyWindowInput]) async {
    guard let previousSprint = persisted.sprint else { return }
    do {
      let timeZone = TimeZone.autoupdatingCurrent
      let sprint = try Sprint(
        id: previousSprint.id,
        startedAt: previousSprint.startedAt,
        endDate: endDate,
        timeZoneIdentifier: timeZone.identifier,
        broadStudyDomain: previousSprint.broadStudyDomain,
        createdAt: previousSprint.createdAt
      )
      let windows = try inputs.enumerated().map { index, input in
        let components = Calendar.autoupdatingCurrent.dateComponents(
          [.hour, .minute], from: input.localStartDate)
        let start = try LocalClockTime(
          hour: components.hour ?? 19, minute: components.minute ?? 0)
        let total = start.minutesFromMidnight + input.durationMinutes
        let end = try LocalClockTime(hour: (total / 60) % 24, minute: total % 60)
        let previous = persisted.windows.first(where: { $0.id == input.id })
        return try StudyWindow(
          id: input.id,
          sprintID: sprint.id,
          recurrenceDays: input.recurrenceDays,
          localStart: start,
          localEnd: end,
          enabled: previous?.enabled ?? true,
          label: previous?.label ?? "Study session \(index + 1)"
        )
      }
      try ScheduleEngine.validate(windows)
      try screenTime.registerRecurringWindows(windows, sprint: sprint)
      persisted.sprint = sprint
      persisted.windows = windows
      try await save()
      telemetry.track(.sprintAction, properties: ["action": "schedule_created"])
    } catch {
      alertMessage = error.localizedDescription
    }
  }

  func saveEditedSelection() {
    do {
      try screenTime.persistSelection()
      screenTime.refreshActiveShieldAfterSelectionChange()
    } catch {
      alertMessage = error.localizedDescription
    }
  }

  func emergencyPause() async {
    guard let index = persisted.sessions.lastIndex(where: { $0.endedAt == nil }) else { return }
    do {
      let pauseUntil = try screenTime.emergencyPause(for: persisted.sessions[index])
      persisted.sessions[index].state = .paused
      persisted.sessions[index].emergencyPauseUntil = pauseUntil
      try await save()
      telemetry.track(.emergencyAction, properties: ["action": "pause_used"])
    } catch {
      // Shield removal is attempted before re-registration. Report a calm, truthful state.
      persisted.sessions[index].state = .unknown
      try? await save()
      alertMessage =
        "The shield was removed, but \(AppEnvironment.appName) could not verify automatic resume. You can resume or end the session from this screen."
    }
  }

  func resumeSession() async {
    guard let index = persisted.sessions.lastIndex(where: { $0.endedAt == nil }) else { return }
    do {
      var current = persisted.sessions[index]
      current.state = .active
      current.emergencyPauseUntil = nil
      screenTime.endCurrentSession()
      try screenTime.startOneOffSession(current)
      persisted.sessions[index] = current
      try await save()
    } catch {
      persisted.sessions[index].state = .unknown
      try? await save()
      alertMessage = error.localizedDescription
    }
  }

  func endToday(checkIn: LocalCheckIn? = nil) async {
    guard let index = persisted.sessions.lastIndex(where: { $0.endedAt == nil }) else { return }
    screenTime.endCurrentSession()
    persisted.sessions[index] = SessionReducer.reduce(
      persisted.sessions[index],
      action: .ended(now: Date(), checkIn: checkIn)
    )
    try? await save()
    telemetry.track(.emergencyAction, properties: ["action": "session_ended"])
    telemetry.track(.sprintAction, properties: ["action": "session_ended"])
  }

  func saveCheckIn(_ checkIn: LocalCheckIn) async {
    guard let index = persisted.sessions.indices.last else { return }
    persisted.sessions[index].localCheckIn = checkIn
    persisted.reflections.append(
      LocalReflection(sessionID: persisted.sessions[index].id, outcomeCategory: checkIn))
    try? await save()
  }

  func createRuleDraft(desiredHours: Double = 7) {
    guard let sprint = persisted.sprint else { return }
    do {
      let request = try PlanningRequest(
        sprintEndDate: sprint.endDate,
        timeZoneIdentifier: sprint.timeZoneIdentifier,
        broadStudyDomain: sprint.broadStudyDomain,
        desiredWeeklyHours: desiredHours,
        preferredTimes: persisted.windows.flatMap { window in
          window.recurrenceDays.map { PreferredStudyTime(weekday: $0, start: window.localStart) }
        }
      )
      latestDraft = RuleBasedPlanner.makeDraft(from: request)
      latestDraftOrigin = .rules
    } catch {
      alertMessage = error.localizedDescription
    }
  }

  func requestAIDraft(consentAcknowledged: Bool, desiredHours: Double = 7) async {
    guard let sprint = persisted.sprint else { return }
    let formatter = ISO8601DateFormatter()
    let request = AIPlanningRequest(
      sprintEndDate: formatter.string(from: sprint.endDate),
      broadStudyDomain: sprint.broadStudyDomain,
      desiredWeeklyHours: desiredHours,
      preferredTimes: persisted.windows.flatMap { window in
        window.recurrenceDays.map { PreferredStudyTime(weekday: $0, start: window.localStart) }
      },
      selfReportedConfidence: nil,
      consentAcknowledged: consentAcknowledged
    )
    isRequestingAI = true
    defer { isRequestingAI = false }
    do {
      let response = try await aiClient.makeDraft(request)
      latestDraft = response.draft
      latestDraftOrigin = .ai
    } catch {
      alertMessage = error.localizedDescription
    }
  }

  func saveLatestDraft() async {
    guard let sprint = persisted.sprint, let draft = latestDraft else { return }
    let description = draft.sessions.map { session in
      "\(session.weekday.shortName) \(String(format: "%02d:%02d", session.start.hour, session.start.minute)) · \(session.durationMinutes) min"
    }.joined(separator: "\n")
    persisted.plans.append(
      LocalPlan(sprintID: sprint.id, userVisiblePlan: description, createdBy: latestDraftOrigin))
    latestDraft = nil
    try? await save()
  }

  func setTelemetry(_ enabled: Bool) async {
    persisted.privacy.telemetryConsent = enabled ? .enabled : .disabled
    telemetry.apply(consent: persisted.privacy.telemetryConsent)
    telemetry.track(
      .telemetryConsentChanged, properties: ["state": enabled ? "enabled" : "disabled"])
    try? await save()
  }

  func deleteAllLocalData() async {
    screenTime.deleteAllLocalControls()
    telemetry.apply(consent: .disabled)
    do {
      try await repository.deleteAll()
      persisted = .empty
      latestDraft = nil
    } catch {
      alertMessage =
        "\(AppEnvironment.appName) could not finish deleting local data. Please try again."
    }
  }

  private func save() async throws {
    try await repository.save(persisted)
  }

  private func makeUITestState(activeSession: Bool) -> PersistedAppState {
    let now = Date()
    let end = Calendar.current.date(byAdding: .day, value: 30, to: now)!
    guard
      let sprint = try? Sprint(
        startedAt: now,
        endDate: end,
        timeZoneIdentifier: TimeZone.autoupdatingCurrent.identifier,
        broadStudyDomain: .certification
      )
    else { return .empty }
    var state = PersistedAppState.empty
    state.sprint = sprint
    state.onboardingComplete = true
    if activeSession,
      let session = try? SessionState(
        source: .oneOff,
        plannedStart: now,
        plannedEnd: now.addingTimeInterval(3_000),
        state: .active,
        label: "Focused study"
      )
    {
      state.sessions = [session]
    }
    return state
  }
}
