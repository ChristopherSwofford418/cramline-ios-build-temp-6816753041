import CramlineCore
import FamilyControls
import SwiftUI

struct OnboardingView: View {
  @ObservedObject var model: AppModel
  @ObservedObject private var screenTime: ScreenTimeCoordinator
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var step = 0
  @State private var ageConfirmed = false
  @State private var endDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
  @State private var domain: BroadStudyDomain = .certification
  @State private var startTime = Calendar.current.date(from: DateComponents(hour: 19, minute: 0))!
  @State private var durationMinutes = 60
  @State private var precommitmentAccepted = false
  @State private var pickerPresented = false
  @State private var isFinishing = false

  init(model: AppModel) {
    self.model = model
    self.screenTime = model.screenTime
  }

  var body: some View {
    NavigationStack {
      ZStack {
        CramlineBackground()
        ScrollView {
          VStack(spacing: 18) {
            progressHeader
            CramlineCard {
              Group {
                switch step {
                case 0: welcome
                case 1: sprint
                case 2: schedule
                case 3: precommitment
                case 4: targets
                default: ready
                }
              }
              .id(step)
              .transition(
                reduceMotion
                  ? .opacity
                  : .asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)))
            }
          }
          .frame(maxWidth: CramlineTheme.contentWidth)
          .padding(.horizontal, 20)
          .padding(.top, 12)
          .padding(.bottom, 112)
          .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
      }
      .safeAreaInset(edge: .bottom) { controls }
      .navigationTitle(AppEnvironment.appName)
      .navigationBarTitleDisplayMode(.inline)
      .familyActivityPicker(isPresented: $pickerPresented, selection: $screenTime.selection)
      .onChange(of: pickerPresented) { isPresented in
        if !isPresented { screenTime.finalizeSelectionPicker() }
      }
      .animation(reduceMotion ? nil : .easeInOut(duration: 0.28), value: step)
    }
  }

  private var progressHeader: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        CramlineEyebrow(text: "SETUP · STEP \(step + 1) OF 6")
        Spacer()
        Text("\(Int(progress * 100))%")
          .font(.caption.monospacedDigit().weight(.bold))
          .foregroundStyle(CramlineTheme.accent)
      }
      GeometryReader { proxy in
        ZStack(alignment: .leading) {
          Capsule().fill(CramlineTheme.accent.opacity(0.12))
          Capsule()
            .fill(
              LinearGradient(
                colors: [CramlineTheme.accent, CramlineTheme.accentBright],
                startPoint: .leading,
                endPoint: .trailing))
            .frame(width: proxy.size.width * progress)
        }
      }
      .frame(height: 8)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("Onboarding step \(step + 1) of 6")
      .accessibilityValue("\(Int(progress * 100)) percent complete")
    }
    .padding(.horizontal, 2)
  }

  private var welcome: some View {
    VStack(alignment: .leading, spacing: 20) {
      heroIcon("book.closed.fill", tint: CramlineTheme.amber)
      CramlineEyebrow(text: "A CALMER RUNWAY")
      Text("Build a study boundary you control.")
        .font(.system(.largeTitle, design: .rounded, weight: .bold))
        .foregroundStyle(CramlineTheme.ink)
      Text("A self-directed focus barrier for professional exam study sprints.")
        .font(.title3.weight(.semibold))
      Text(
        "\(AppEnvironment.appName) is for adults preparing for a high-stakes exam over the next 14–90 days. It is not parental control, proctoring, treatment, or a guarantee of focus or results."
      )
      .foregroundStyle(.secondary)
      Toggle("I confirm I am 18 or older", isOn: $ageConfirmed)
        .font(.headline)
        .tint(CramlineTheme.accent)
        .padding()
        .background(CramlineTheme.warmSurface, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityHint("No date of birth is collected")
    }
  }

  private var sprint: some View {
    VStack(alignment: .leading, spacing: 20) {
      heroIcon("calendar.badge.clock", tint: CramlineTheme.amber)
      CramlineEyebrow(text: "YOUR RUNWAY")
      Text("Choose your study sprint")
        .font(.system(.largeTitle, design: .rounded, weight: .bold))
      Text("Pick a finish line between 14 and 90 days away. You can adjust it later within this sprint.")
        .foregroundStyle(.secondary)
      fieldCard {
        DatePicker(
          "Sprint end date",
          selection: $endDate,
          in: minimumEndDate...maximumEndDate,
          displayedComponents: .date
        )
        Divider()
        Picker("Broad study domain", selection: $domain) {
          ForEach(BroadStudyDomain.allCases, id: \.self) { item in
            Text(item.displayName).tag(item)
          }
        }
      }
      HStack(alignment: .top, spacing: 12) {
        Image(systemName: "location.slash.fill").foregroundStyle(CramlineTheme.accent)
        VStack(alignment: .leading, spacing: 4) {
          Text("Only broad planning context").font(.headline)
          Text("You never need to enter an exam provider, score, school, or employer.")
            .font(.callout)
            .foregroundStyle(.secondary)
        }
      }
      Text(
        "Local time zone: \(TimeZone.autoupdatingCurrent.localizedName(for: .standard, locale: .current) ?? TimeZone.autoupdatingCurrent.identifier)"
      )
      .font(.footnote)
      .foregroundStyle(.secondary)
    }
  }

  private var schedule: some View {
    VStack(alignment: .leading, spacing: 20) {
      heroIcon("clock.badge.checkmark.fill", tint: CramlineTheme.amber)
      CramlineEyebrow(text: "FIRST STUDY WINDOW")
      Text("Give study a reliable place in your day")
        .font(.system(.largeTitle, design: .rounded, weight: .bold))
      Text("Start with one daily window. You can later choose days and keep up to three windows.")
        .foregroundStyle(.secondary)
      fieldCard {
        DatePicker("Local start time", selection: $startTime, displayedComponents: .hourAndMinute)
        Divider()
        Picker("Session length", selection: $durationMinutes) {
          Text("25 minutes").tag(25)
          Text("50 minutes").tag(50)
          Text("60 minutes").tag(60)
          Text("90 minutes").tag(90)
          Text("120 minutes").tag(120)
        }
        .pickerStyle(.menu)
      }
      HStack(spacing: 12) {
        timelineDot("sun.horizon.fill")
        Rectangle().fill(CramlineTheme.accent.opacity(0.20)).frame(height: 2)
        timelineDot("book.pages.fill")
        Rectangle().fill(CramlineTheme.accent.opacity(0.20)).frame(height: 2)
        timelineDot("checkmark")
      }
      .accessibilityHidden(true)
      Label(
        "DeviceActivity scheduling is best effort, not a precision alarm.",
        systemImage: "info.circle"
      )
      .font(.footnote)
      .foregroundStyle(.secondary)
    }
  }

  private var precommitment: some View {
    VStack(alignment: .leading, spacing: 18) {
      heroIcon("shield.lefthalf.filled", tint: CramlineTheme.amber)
      CramlineEyebrow(text: "BEFORE SCREEN TIME")
      Text("Review your precommitment")
        .font(.system(.largeTitle, design: .rounded, weight: .bold))
      Text("The boundary is useful because it is clear—not because it is irreversible.")
        .foregroundStyle(.secondary)
      DisclosureRow(
        icon: "checkmark.shield.fill",
        title: "What \(AppEnvironment.appName) does",
        text:
          "After you authorize Screen Time, iOS can place its shield over apps and websites you choose during scheduled sessions."
      )
      DisclosureRow(
        icon: "xmark.shield",
        title: "What it cannot promise",
        text:
          "It does not lock your phone, prevent uninstalling, read activity or content, detect procrastination, or guarantee exam results."
      )
      DisclosureRow(
        icon: "hand.raised.fill",
        title: "You stay in control",
        text:
          "Emergency pause for 15 minutes and End today’s session remain available without payment, a quiz, a timer, or another person’s permission. You can also revoke Screen Time permission in system settings."
      )
      Toggle("I understand and want to continue", isOn: $precommitmentAccepted)
        .font(.headline)
        .tint(CramlineTheme.accent)
        .padding(.top, 4)
    }
  }

  private var targets: some View {
    VStack(alignment: .leading, spacing: 18) {
      heroIcon("hand.tap.fill", tint: CramlineTheme.amber)
      CramlineEyebrow(text: "PRIVATE SELECTION")
      Text("Choose targets privately")
        .font(.system(.largeTitle, design: .rounded, weight: .bold))
      Text(
        "\(AppEnvironment.appName) uses Apple’s system picker. App and website choices are opaque tokens stored only on this device and are never sent to analytics or AI."
      )
      .foregroundStyle(.secondary)
      HStack {
        authorizationStatus
        Spacer()
        if screenTime.authorizationStatus == .approved {
          Image(systemName: "checkmark.circle.fill")
            .foregroundStyle(CramlineTheme.success)
            .accessibilityHidden(true)
        }
      }
      .padding()
      .background(CramlineTheme.warmSurface, in: RoundedRectangle(cornerRadius: 18))

      Button(screenTime.authorizationStatus == .approved ? "Screen Time permission enabled" : "Enable Screen Time permission") {
        CramlineFeedback.impact()
        Task {
          await screenTime.requestIndividualAuthorization()
          if screenTime.authorizationStatus == .approved { CramlineFeedback.success() }
          model.telemetry.track(
            .screenTimeAuthorizationResult,
            properties: ["result": screenTime.authorizationStatus == .approved ? "granted" : "declined"])
        }
      }
      .buttonStyle(CramlineButtonStyle())
      .disabled(screenTime.authorizationStatus == .approved)

      Button("Open Apple system picker") {
        CramlineFeedback.impact(.medium)
        screenTime.prepareSelectionPicker()
        pickerPresented = true
      }
      .buttonStyle(CramlineButtonStyle(prominent: true))
      .disabled(screenTime.authorizationStatus != .approved)
      .accessibilityHint("Opens Apple’s private app and website selection screen")

      CramlineStatusPill(
        title: "\(screenTime.selectedApplicationCount) individual apps selected",
        systemImage: "app.badge.checkmark")
      Text("\(AppEnvironment.appName) can shield up to 50 individual apps at once.")
        .font(.callout)
        .foregroundStyle(.secondary)
      selectionWarnings
      Text(
        "Review communications, browsers, identity, health, finance, transport, work, education, and exam-provider apps carefully. \(AppEnvironment.appName) never preselects safety-critical apps."
      )
      .font(.footnote)
      .foregroundStyle(.secondary)
    }
  }

  private var ready: some View {
    VStack(alignment: .leading, spacing: 20) {
      heroIcon("checkmark.circle.fill", tint: CramlineTheme.success)
      CramlineEyebrow(text: "READY WHEN YOU ARE", color: CramlineTheme.success)
      Text("Your study runway is ready")
        .font(.system(.largeTitle, design: .rounded, weight: .bold))
      Text(
        "\(AppEnvironment.appName) will ask iOS to apply the system shield during your chosen window. You can change the plan, pause for an emergency, end the session, or revoke permission at any time."
      )
      .foregroundStyle(.secondary)
      ViewThatFits(in: .horizontal) {
        HStack(spacing: 10) { readyPill("calendar", "Scheduled"); readyPill("wifi.slash", "Works offline"); readyPill("hand.raised", "Your control") }
        VStack(alignment: .leading, spacing: 10) { readyPill("calendar", "Scheduled"); readyPill("wifi.slash", "Works offline"); readyPill("hand.raised", "Your control") }
      }
      Text("No score prediction or exam-result promise is made.")
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
  }

  @ViewBuilder
  private var selectionWarnings: some View {
    if screenTime.selectedApplicationCount > 50 {
      Label(
        "Apple supports no more than 50 individual app tokens. Remove at least one selection.",
        systemImage: "exclamationmark.triangle.fill"
      )
      .foregroundStyle(CramlineTheme.danger)
      .font(.callout.weight(.semibold))
    }
    if screenTime.convertedCategorySelection {
      Label(
        "Your category choice was converted to the apps and websites currently inside it. No dynamic category rule is saved. Review the selected count and remove any safety-critical apps in Apple’s picker.",
        systemImage: "checkmark.shield"
      )
      .foregroundStyle(.secondary)
      .font(.callout)
    }
  }

  private var controls: some View {
    HStack(spacing: 12) {
      if step > 0 {
        Button("Back") {
          CramlineFeedback.impact()
          step -= 1
        }
        .buttonStyle(CramlineButtonStyle())
      }
      if step < 5 {
        Button("Continue") {
          CramlineFeedback.impact()
          step += 1
        }
        .buttonStyle(CramlineButtonStyle(prominent: true))
        .disabled(!canContinue)
      } else {
        Button {
          CramlineFeedback.impact(.medium)
          isFinishing = true
          let components = Calendar.current.dateComponents([.hour, .minute], from: startTime)
          Task {
            await model.completeOnboarding(
              endDate: endDate,
              domain: domain,
              startHour: components.hour ?? 19,
              startMinute: components.minute ?? 0,
              durationMinutes: durationMinutes
            )
            isFinishing = false
            if model.persisted.onboardingComplete { CramlineFeedback.success() }
          }
        } label: {
          HStack {
            if isFinishing { ProgressView().tint(.white) }
            Text(isFinishing ? "Saving plan…" : "Finish setup")
          }
        }
        .buttonStyle(CramlineButtonStyle(prominent: true))
        .disabled(isFinishing)
      }
    }
    .frame(maxWidth: CramlineTheme.contentWidth)
    .padding(.horizontal, 20)
    .padding(.vertical, 12)
    .background(.ultraThinMaterial)
  }

  private var authorizationStatus: some View {
    Label(authorizationText, systemImage: screenTime.authorizationStatus == .approved ? "checkmark.shield.fill" : "shield.slash")
      .font(.headline)
      .foregroundStyle(screenTime.authorizationStatus == .approved ? CramlineTheme.success : .secondary)
      .accessibilityElement(children: .combine)
  }

  private var authorizationText: String {
    switch screenTime.authorizationStatus {
    case .approved: return "Screen Time permission enabled"
    case .denied: return "Permission declined or revoked"
    case .notDetermined: return "Permission not requested"
    @unknown default: return "Permission state unknown"
    }
  }

  private var canContinue: Bool {
    switch step {
    case 0: return ageConfirmed
    case 3: return precommitmentAccepted
    case 4:
      return screenTime.authorizationStatus == .approved
        && screenTime.canSaveSelection
        && (!screenTime.selection.applicationTokens.isEmpty || !screenTime.selection.webDomainTokens.isEmpty)
    default: return true
    }
  }

  private var progress: Double { Double(step + 1) / 6.0 }

  private var minimumEndDate: Date {
    Calendar.current.date(byAdding: .day, value: 14, to: Calendar.current.startOfDay(for: Date()))!
  }

  private var maximumEndDate: Date {
    Calendar.current.date(byAdding: .day, value: 90, to: Calendar.current.startOfDay(for: Date()))!
  }

  private func heroIcon(_ name: String, tint: Color) -> some View {
    Image(systemName: name)
      .font(.system(size: 30, weight: .semibold))
      .foregroundStyle(tint)
      .frame(width: 66, height: 66)
      .background(CramlineTheme.deepEvergreen, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
      .shadow(color: CramlineTheme.deepEvergreen.opacity(0.20), radius: 12, y: 7)
      .accessibilityHidden(true)
  }

  private func timelineDot(_ icon: String) -> some View {
    Image(systemName: icon)
      .font(.caption.bold())
      .foregroundStyle(CramlineTheme.accent)
      .frame(width: 34, height: 34)
      .background(CramlineTheme.accent.opacity(0.12), in: Circle())
  }

  private func readyPill(_ icon: String, _ text: String) -> some View {
    Label(text, systemImage: icon)
      .font(.callout.weight(.semibold))
      .padding(.horizontal, 12)
      .padding(.vertical, 9)
      .background(CramlineTheme.success.opacity(0.10), in: Capsule())
  }

  private func fieldCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    VStack(spacing: 14) { content() }
      .padding()
      .background(CramlineTheme.warmSurface, in: RoundedRectangle(cornerRadius: 18))
  }
}

private struct DisclosureRow: View {
  let icon: String
  let title: String
  let text: String

  var body: some View {
    HStack(alignment: .top, spacing: 14) {
      Image(systemName: icon)
        .font(.title3.weight(.semibold))
        .foregroundStyle(CramlineTheme.accent)
        .frame(width: 30)
        .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 6) {
        Text(title).font(.headline)
        Text(text).font(.callout).foregroundStyle(.secondary)
      }
    }
    .padding()
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(CramlineTheme.warmSurface, in: RoundedRectangle(cornerRadius: 18))
    .accessibilityElement(children: .combine)
  }
}
