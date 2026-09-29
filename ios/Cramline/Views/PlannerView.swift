import CramlineCore
import FamilyControls
import Foundation
import SwiftUI

private struct EditableStudyWindow: Identifiable {
  var id: UUID
  var recurrenceDays: Set<Weekday>
  var start: Date
  var durationMinutes: Int
}

struct PlannerView: View {
  @ObservedObject var model: AppModel
  @ObservedObject private var purchases: PurchaseController
  @ObservedObject private var screenTime: ScreenTimeCoordinator
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var desiredHours = 7.0
  @State private var showingAIConsent = false
  @State private var showingTargetPicker = false
  @State private var scheduleWindows: [EditableStudyWindow]
  @State private var sprintEndDate: Date
  @State private var isSavingSchedule = false
  @State private var scheduleNotice: String?
  @State private var targetNotice: String?

  init(model: AppModel) {
    self.model = model
    self.purchases = model.purchases
    self.screenTime = model.screenTime

    let existingWindows = model.persisted.windows.map { window in
      var components = DateComponents()
      components.hour = window.localStart.hour
      components.minute = window.localStart.minute
      let start = Calendar.autoupdatingCurrent.date(from: components) ?? Date()
      let delta = (window.localEnd.minutesFromMidnight - window.localStart.minutesFromMidnight + 1_440) % 1_440
      return EditableStudyWindow(
        id: window.id,
        recurrenceDays: window.recurrenceDays,
        start: start,
        durationMinutes: max(delta, 25))
    }
    _scheduleWindows = State(
      initialValue: existingWindows.isEmpty
        ? [EditableStudyWindow(id: UUID(), recurrenceDays: Set(Weekday.allCases), start: Date(), durationMinutes: 50)]
        : existingWindows)
    _sprintEndDate = State(
      initialValue: model.activeSprint?.endDate
        ?? Calendar.current.date(byAdding: .day, value: 30, to: Date())!)
  }

  var body: some View {
    ZStack {
      CramlineBackground()
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          pageHeader
          scheduleCard
          targetsCard
          planningCard
          draftArea
          savedPlansCard
        }
        .frame(maxWidth: CramlineTheme.wideContentWidth, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
      }
      .scrollIndicators(.hidden)
    }
    .navigationTitle("Plan")
    .navigationBarTitleDisplayMode(.inline)
    .familyActivityPicker(isPresented: $showingTargetPicker, selection: $screenTime.selection)
    .onChange(of: showingTargetPicker) { isPresented in
      if !isPresented {
        screenTime.finalizeSelectionPicker()
        targetNotice = "Selection reviewed. Save it when the count and safety-critical apps look right."
      }
    }
    .confirmationDialog(
      "Send this planning request to AI?", isPresented: $showingAIConsent,
      titleVisibility: .visible
    ) {
      Button("Send shown plan fields") {
        CramlineFeedback.impact(.medium)
        Task { await model.requestAIDraft(consentAcknowledged: true, desiredHours: desiredHours) }
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text(AIPlanningRequest.disclosure)
    }
    .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: model.latestDraft != nil)
  }

  private var pageHeader: some View {
    VStack(alignment: .leading, spacing: 7) {
      CramlineEyebrow(text: "LOCAL STUDY PLAN")
      Text("Shape a week you can repeat.")
        .font(.system(.largeTitle, design: .rounded, weight: .bold))
        .foregroundStyle(CramlineTheme.ink)
      Text("Schedule shields and create a practical draft without sending study details anywhere.")
        .foregroundStyle(.secondary)
    }
  }

  private var scheduleCard: some View {
    CramlineCard {
      VStack(alignment: .leading, spacing: 18) {
        sectionHeader("Edit your local schedule", icon: "calendar.badge.clock", detail: "Up to three daily windows")
        if let sprint = model.activeSprint {
          DatePicker(
            "Sprint ends",
            selection: $sprintEndDate,
            in: sprintRange(sprint),
            displayedComponents: .date
          )
          .padding()
          .background(CramlineTheme.warmSurface, in: RoundedRectangle(cornerRadius: 16))
        }
        ForEach(Array(scheduleWindows.indices), id: \.self) { index in
          windowEditor(index: index)
        }
        if scheduleWindows.count < 3 {
          Button {
            CramlineFeedback.impact()
            scheduleWindows.append(
              EditableStudyWindow(
                id: UUID(), recurrenceDays: Set(Weekday.allCases), start: Date(), durationMinutes: 50))
          } label: {
            Label("Add another daily window", systemImage: "plus.circle.fill")
          }
          .buttonStyle(CramlineButtonStyle())
        }
        Button {
          saveSchedule()
        } label: {
          HStack {
            if isSavingSchedule { ProgressView().tint(.white) }
            Text(isSavingSchedule ? "Saving schedule…" : "Save schedule changes")
            Spacer()
            Image(systemName: "checkmark")
          }
        }
        .buttonStyle(CramlineButtonStyle(prominent: true))
        .disabled(isSavingSchedule || scheduleWindows.contains(where: { $0.recurrenceDays.isEmpty }))
        if let scheduleNotice {
          successNotice(scheduleNotice)
        }
        Label(
          "Times use the device’s current local time zone. DeviceActivity callbacks are best effort, not precision alarms.",
          systemImage: "info.circle"
        )
        .font(.footnote)
        .foregroundStyle(.secondary)
      }
    }
  }

  private var targetsCard: some View {
    CramlineCard(tint: CramlineTheme.warmSurface) {
      VStack(alignment: .leading, spacing: 16) {
        sectionHeader("Selected apps and websites", icon: "square.grid.2x2.fill", detail: "Apple’s private system picker")
        HStack {
          VStack(alignment: .leading, spacing: 3) {
            Text("\(screenTime.selectedApplicationCount)")
              .font(.system(.largeTitle, design: .rounded, weight: .bold))
              .foregroundStyle(CramlineTheme.ink)
            Text("individual apps selected")
              .font(.callout)
              .foregroundStyle(.secondary)
          }
          Spacer()
          Image(systemName: "hand.tap.fill")
            .font(.title2)
            .foregroundStyle(CramlineTheme.accent)
            .frame(width: 54, height: 54)
            .background(CramlineTheme.accent.opacity(0.10), in: Circle())
            .accessibilityHidden(true)
        }
        Button {
          CramlineFeedback.impact()
          screenTime.prepareSelectionPicker()
          showingTargetPicker = true
        } label: {
          Label("Review in Apple’s system picker", systemImage: "slider.horizontal.3")
        }
        .buttonStyle(CramlineButtonStyle())
        .accessibilityHint("Opens Apple’s private app and website selection screen")
        if screenTime.selectedApplicationCount > AppEnvironment.maximumSelectedApplications {
          Label("Reduce the selection to 50 individual apps before saving.", systemImage: "exclamationmark.triangle.fill")
            .font(.callout.weight(.semibold))
            .foregroundStyle(CramlineTheme.danger)
        }
        if screenTime.convertedCategorySelection {
          Text("The category choice was converted to its currently installed apps and websites; no dynamic category rule is saved. Review the selection before saving.")
            .font(.callout)
            .foregroundStyle(.secondary)
        }
        Button("Save selected targets") {
          CramlineFeedback.impact(.medium)
          model.alertMessage = nil
          model.saveEditedSelection()
          if model.alertMessage == nil {
            targetNotice = "Selected opaque tokens saved on this device."
            CramlineFeedback.success()
          }
        }
        .buttonStyle(CramlineButtonStyle(prominent: true))
        .disabled(!screenTime.canSaveSelection || (screenTime.selection.applicationTokens.isEmpty && screenTime.selection.webDomainTokens.isEmpty))
        if let targetNotice { successNotice(targetNotice) }
      }
    }
  }

  private var planningCard: some View {
    CramlineCard {
      VStack(alignment: .leading, spacing: 18) {
        sectionHeader("Weekly planning draft", icon: "wand.and.stars", detail: "Deterministic and offline")
        VStack(alignment: .leading, spacing: 8) {
          HStack(alignment: .firstTextBaseline) {
            Text("Desired study time").font(.headline)
            Spacer()
            Text("\(desiredHours, specifier: "%.1f") hours/week")
              .font(.headline.monospacedDigit())
              .foregroundStyle(CramlineTheme.accent)
          }
          Slider(value: $desiredHours, in: 1...40, step: 0.5)
            .accessibilityLabel("Desired study time")
            .accessibilityValue("\(desiredHours, specifier: "%.1f") hours per week")
          HStack {
            Text("1h"); Spacer(); Text("40h")
          }
          .font(.caption)
          .foregroundStyle(.secondary)
        }
        Button {
          CramlineFeedback.impact(.medium)
          withAnimation(reduceMotion ? nil : .spring(response: 0.36, dampingFraction: 0.84)) {
            model.createRuleDraft(desiredHours: desiredHours)
          }
          if model.latestDraft != nil { CramlineFeedback.success() }
        } label: {
          Label("Draft on this device", systemImage: "cpu")
        }
        .buttonStyle(CramlineButtonStyle(prominent: true))
        Label("The on-device planner works offline and sends nothing anywhere.", systemImage: "wifi.slash")
          .font(.footnote)
          .foregroundStyle(.secondary)
        aiAvailability
      }
    }
  }

  @ViewBuilder
  private var aiAvailability: some View {
    if AppEnvironment.isPremiumOfferAvailable {
      Divider()
      HStack(alignment: .top, spacing: 12) {
        Image(systemName: "sparkles").foregroundStyle(CramlineTheme.amber)
        VStack(alignment: .leading, spacing: 6) {
          Text("Optional AI draft").font(.headline)
          Text(purchases.hasPremium ? "Available with your Premium access after per-request review." : "Premium feature. The free on-device planner remains available.")
            .font(.callout)
            .foregroundStyle(.secondary)
          Button(model.isRequestingAI ? "Requesting draft…" : "Ask AI to draft my week") { showingAIConsent = true }
            .disabled(model.isRequestingAI || !purchases.hasPremium)
        }
      }
    } else {
      HStack(alignment: .top, spacing: 12) {
        Image(systemName: "sparkles.slash.fill")
          .foregroundStyle(.secondary)
          .accessibilityHidden(true)
        VStack(alignment: .leading, spacing: 4) {
          Text("AI planning unavailable in this build").font(.headline)
          Text("Nothing is sent to an AI service. The complete offline drafting route above remains available.")
            .font(.callout)
            .foregroundStyle(.secondary)
        }
      }
      .padding()
      .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
      .accessibilityElement(children: .combine)
    }
  }

  @ViewBuilder
  private var draftArea: some View {
    if let draft = model.latestDraft {
      CramlineCard(tint: Color(red: 0.91, green: 0.96, blue: 0.91)) {
        VStack(alignment: .leading, spacing: 16) {
          HStack {
            CramlineStatusPill(title: "Unsaved draft", systemImage: "pencil.and.list.clipboard", tint: CramlineTheme.success)
            Spacer()
            Text("Review first").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
          }
          ForEach(draft.sessions.indices, id: \.self) { index in
            let session = draft.sessions[index]
            HStack(alignment: .top, spacing: 12) {
              Text("\(index + 1)")
                .font(.caption.monospacedDigit().bold())
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(CramlineTheme.accent, in: Circle())
              VStack(alignment: .leading, spacing: 3) {
                Text("\(session.weekday.shortName) · \(format(session.start))").font(.headline)
                Text("\(session.durationMinutes) minutes").font(.callout).foregroundStyle(.secondary)
              }
              Spacer()
            }
          }
          Divider()
          Label(draft.breakCadence, systemImage: "cup.and.saucer.fill").font(.callout)
          Label(draft.implementationIntention, systemImage: "scope").font(.callout)
          Text("Draft only — review before saving.").font(.footnote.bold())
          Button("Save this draft") {
            CramlineFeedback.impact(.medium)
            Task {
              await model.saveLatestDraft()
              CramlineFeedback.success()
            }
          }
          .buttonStyle(CramlineButtonStyle(prominent: true))
          Button("Discard draft", role: .destructive) {
            CramlineFeedback.warning()
            model.latestDraft = nil
          }
          .frame(maxWidth: .infinity)
        }
      }
      .transition(.scale(scale: 0.97).combined(with: .opacity))
    }
  }

  private var savedPlansCard: some View {
    CramlineCard(tint: CramlineTheme.warmSurface) {
      VStack(alignment: .leading, spacing: 14) {
        sectionHeader("Saved locally", icon: "tray.full.fill", detail: "On this device")
        if model.persisted.plans.isEmpty {
          HStack(alignment: .top, spacing: 12) {
            Image(systemName: "tray")
              .font(.title2)
              .foregroundStyle(CramlineTheme.accent)
              .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
              Text("No saved draft yet").font(.headline)
              Text("Create an offline weekly draft above, review it, then save it here.")
                .font(.callout)
                .foregroundStyle(.secondary)
            }
          }
          .accessibilityElement(children: .combine)
        } else {
          ForEach(model.persisted.plans) { plan in
            Text(plan.userVisiblePlan)
              .font(.callout.monospaced())
              .padding()
              .frame(maxWidth: .infinity, alignment: .leading)
              .background(.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 14))
          }
        }
      }
    }
  }

  private func windowEditor(index: Int) -> some View {
    let binding = $scheduleWindows[index]
    return VStack(alignment: .leading, spacing: 14) {
      HStack {
        VStack(alignment: .leading, spacing: 3) {
          Text("Study window \(index + 1)").font(.headline)
          Text(daySummary(scheduleWindows[index].recurrenceDays))
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        Spacer()
        if scheduleWindows.count > 1 {
          Button(role: .destructive) {
            CramlineFeedback.warning()
            scheduleWindows.remove(at: index)
          } label: {
            Label("Remove window \(index + 1)", systemImage: "trash")
              .labelStyle(.iconOnly)
          }
          .accessibilityLabel("Remove study window \(index + 1)")
        }
      }
      LazyVGrid(columns: [GridItem(.adaptive(minimum: 52), spacing: 8)], spacing: 8) {
        ForEach(Weekday.allCases, id: \.self) { day in
          let selected = scheduleWindows[index].recurrenceDays.contains(day)
          Button(day.shortName) {
            CramlineFeedback.impact()
            if selected { binding.wrappedValue.recurrenceDays.remove(day) }
            else { binding.wrappedValue.recurrenceDays.insert(day) }
          }
          .font(.caption.bold())
          .frame(minWidth: 44, minHeight: 38)
          .background(selected ? CramlineTheme.accent : Color.clear, in: Capsule())
          .foregroundStyle(selected ? .white : CramlineTheme.accent)
          .overlay(Capsule().stroke(CramlineTheme.accent.opacity(selected ? 0 : 0.24)))
          .accessibilityValue(selected ? "Selected" : "Not selected")
        }
      }
      if scheduleWindows[index].recurrenceDays.isEmpty {
        Text("Choose at least one day.").font(.caption.weight(.semibold)).foregroundStyle(CramlineTheme.danger)
      }
      DatePicker("Start", selection: binding.start, displayedComponents: .hourAndMinute)
      Stepper("Length: \(scheduleWindows[index].durationMinutes) minutes", value: binding.durationMinutes, in: 25...180, step: 5)
    }
    .padding()
    .background(CramlineTheme.warmSurface, in: RoundedRectangle(cornerRadius: 18))
  }

  private func saveSchedule() {
    CramlineFeedback.impact(.medium)
    model.alertMessage = nil
    scheduleNotice = nil
    isSavingSchedule = true
    Task {
      await model.updateSprintAndWindows(
        endDate: sprintEndDate,
        inputs: scheduleWindows.map {
          StudyWindowInput(id: $0.id, recurrenceDays: $0.recurrenceDays, localStartDate: $0.start, durationMinutes: $0.durationMinutes)
        })
      isSavingSchedule = false
      if model.alertMessage == nil {
        scheduleNotice = "Schedule saved locally and submitted to iOS for best-effort registration."
        CramlineFeedback.success()
      }
    }
  }

  private func sectionHeader(_ title: String, icon: String, detail: String) -> some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: icon)
        .font(.headline)
        .foregroundStyle(CramlineTheme.accent)
        .frame(width: 38, height: 38)
        .background(CramlineTheme.accent.opacity(0.10), in: Circle())
        .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 2) {
        Text(title).font(.title3.bold())
        Text(detail).font(.caption).foregroundStyle(.secondary)
      }
    }
  }

  private func successNotice(_ text: String) -> some View {
    Label(text, systemImage: "checkmark.circle.fill")
      .font(.callout.weight(.semibold))
      .foregroundStyle(CramlineTheme.success)
      .padding(12)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(CramlineTheme.success.opacity(0.09), in: RoundedRectangle(cornerRadius: 14))
      .accessibilityElement(children: .combine)
  }

  private func sprintRange(_ sprint: Sprint) -> ClosedRange<Date> {
    let calendar = Calendar.autoupdatingCurrent
    let minimum = calendar.date(byAdding: .day, value: 14, to: sprint.startedAt)!
    let maximum = calendar.date(byAdding: .day, value: 90, to: sprint.startedAt)!
    return minimum...maximum
  }

  private func format(_ time: LocalClockTime) -> String {
    String(format: "%02d:%02d", time.hour, time.minute)
  }

  private func daySummary(_ days: Set<Weekday>) -> String {
    if days.count == Weekday.allCases.count { return "Every day" }
    if days.isEmpty { return "No days selected" }
    return Weekday.allCases.filter(days.contains).map(\.shortName).joined(separator: ", ")
  }
}
