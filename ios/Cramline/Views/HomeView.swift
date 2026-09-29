import CramlineCore
import SwiftUI

struct HomeView: View {
  @ObservedObject var model: AppModel
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var showingEndConfirmation = false
  @State private var showingPauseConfirmation = false
  @State private var actionInFlight = false

  var body: some View {
    ZStack {
      CramlineBackground()
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          header
          sprintProgress
          Group {
            if let session = model.currentSession {
              activeSession(session)
                .transition(.scale(scale: 0.96).combined(with: .opacity))
            } else {
              ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 18) {
                  nextSession.frame(maxWidth: .infinity)
                  startCard.frame(maxWidth: .infinity)
                }
                VStack(spacing: 18) { nextSession; startCard }
              }
              .transition(.opacity)
            }
          }
          safetyCard
        }
        .frame(maxWidth: CramlineTheme.wideContentWidth, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
      }
      .scrollIndicators(.hidden)
    }
    .navigationTitle("Today")
    .navigationBarTitleDisplayMode(.inline)
    .animation(reduceMotion ? nil : .spring(response: 0.38, dampingFraction: 0.88), value: model.currentSession?.state)
    .confirmationDialog("Pause the shield for 15 minutes?", isPresented: $showingPauseConfirmation) {
      Button("Pause shield for 15 minutes") {
        CramlineFeedback.warning()
        actionInFlight = true
        Task {
          await model.emergencyPause()
          actionInFlight = false
        }
      }
      .accessibilityIdentifier("confirm-emergency-pause")
      Button("Keep studying", role: .cancel) {}
    } message: {
      Text("The app’s shield is removed immediately, then Cramline will attempt to resume it after 15 minutes. Exact callback timing is not guaranteed.")
    }
    .confirmationDialog("End today’s session?", isPresented: $showingEndConfirmation) {
      Button("End today’s session", role: .destructive) {
        CramlineFeedback.warning()
        actionInFlight = true
        Task {
          await model.endToday(checkIn: .endedEarly)
          actionInFlight = false
        }
      }
      .accessibilityIdentifier("confirm-end-session")
      .accessibilityLabel("End today’s session — free and no penalty")
      Button("Keep studying", role: .cancel) {}
    } message: {
      Text("The study shield will be removed immediately. This action is free and has no penalty.")
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 7) {
      CramlineEyebrow(text: "YOUR EXAM SPRINT")
      Text(model.currentSession == nil ? "Make room for the work." : "Make this session count.")
        .font(.system(.largeTitle, design: .rounded, weight: .bold))
        .foregroundStyle(CramlineTheme.ink)
      if let sprint = model.activeSprint {
        Text("\(sprint.broadStudyDomain?.displayName ?? "Professional exam") · ends \(sprint.endDate.formatted(date: .long, time: .omitted))")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
    }
  }

  private var sprintProgress: some View {
    CramlineCard(tint: CramlineTheme.warmSurface, padding: 16) {
      HStack(spacing: 16) {
        ZStack {
          Circle().stroke(CramlineTheme.accent.opacity(0.14), lineWidth: 7)
          Circle()
            .trim(from: 0, to: sprintFraction)
            .stroke(CramlineTheme.accent, style: StrokeStyle(lineWidth: 7, lineCap: .round))
            .rotationEffect(.degrees(-90))
          Text("\(Int(sprintFraction * 100))%")
            .font(.caption.monospacedDigit().bold())
        }
        .frame(width: 68, height: 68)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Sprint progress")
        .accessibilityValue("\(Int(sprintFraction * 100)) percent by elapsed calendar time")
        VStack(alignment: .leading, spacing: 4) {
          Text("Sprint timeline").font(.headline)
          Text(sprintTimelineText)
            .font(.callout)
            .foregroundStyle(.secondary)
          Text("Calendar progress, not a performance score")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        Spacer(minLength: 0)
      }
    }
  }

  private func activeSession(_ session: SessionState) -> some View {
    VStack(alignment: .leading, spacing: 18) {
      HStack(alignment: .top) {
        Label(session.state.displayName, systemImage: stateIcon(session.state))
          .font(.caption.weight(.bold))
          .padding(.horizontal, 11)
          .padding(.vertical, 8)
          .background(.white.opacity(0.15), in: Capsule())
        Spacer()
        Image(systemName: session.state == .paused ? "pause.fill" : "shield.fill")
          .font(.title2.weight(.semibold))
          .padding(13)
          .background(.white.opacity(0.15), in: Circle())
          .accessibilityHidden(true)
      }
      VStack(alignment: .leading, spacing: 6) {
        CramlineEyebrow(
          text: session.state == .paused ? "BREATHING ROOM" : "IN PROGRESS",
          color: .white.opacity(0.76))
        Text(session.label ?? "Study session")
          .font(.system(.title, design: .rounded, weight: .bold))
        Text(activeTimingText(session))
          .font(.title3.monospacedDigit().weight(.semibold))
      }
      HStack(spacing: 10) {
        Label("Ends \(session.plannedEnd.formatted(date: .omitted, time: .shortened))", systemImage: "clock.fill")
        Text("·")
        Text(TimeZone.autoupdatingCurrent.identifier).lineLimit(1)
      }
      .font(.subheadline.weight(.medium))
      .foregroundStyle(.white.opacity(0.82))
      Divider().overlay(.white.opacity(0.22))
      Label(
        session.state == .paused
          ? "The app’s shield is paused. Resume whenever you are ready."
          : "Choose one concrete study outcome before switching tasks.",
        systemImage: session.state == .paused ? "hand.raised.fill" : "scope"
      )
      .font(.callout.weight(.medium))
      .foregroundStyle(.white.opacity(0.92))

      if session.state == .paused || session.state == .unknown {
        Button {
          CramlineFeedback.impact(.medium)
          actionInFlight = true
          Task {
            await model.resumeSession()
            actionInFlight = false
          }
        } label: {
          actionLabel("Resume shield now", icon: "play.fill")
        }
        .buttonStyle(CramlineButtonStyle())
        .tint(.white)
        .disabled(actionInFlight)
      } else {
        Button {
          CramlineFeedback.impact()
          showingPauseConfirmation = true
        } label: {
          actionLabel("Emergency pause — 15 minutes", icon: "pause.fill")
        }
        .buttonStyle(CramlineButtonStyle())
        .tint(.white)
        .disabled(actionInFlight)
        .accessibilityHint("Confirms before removing Cramline shields immediately for up to 15 minutes")
      }
      Button {
        CramlineFeedback.impact()
        showingEndConfirmation = true
      } label: {
        actionLabel("End today’s session", icon: "stop.fill")
      }
      .buttonStyle(CramlineButtonStyle())
      .tint(.white)
      .disabled(actionInFlight)
      .accessibilityHint("Confirms before removing Cramline shields immediately with no penalty")
    }
    .padding(22)
    .foregroundStyle(.white)
    .background {
      ZStack {
        LinearGradient(
          colors: [CramlineTheme.deepEvergreen, CramlineTheme.accent],
          startPoint: .topLeading,
          endPoint: .bottomTrailing)
        Circle()
          .fill(CramlineTheme.amber.opacity(0.16))
          .frame(width: 240, height: 240)
          .blur(radius: 4)
          .offset(x: 180, y: -150)
      }
      .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
    .shadow(color: CramlineTheme.deepEvergreen.opacity(0.24), radius: 22, y: 12)
  }

  private var nextSession: some View {
    CramlineCard {
      if let occurrence = model.nextOccurrence {
        VStack(alignment: .leading, spacing: 10) {
          HStack {
            CramlineStatusPill(title: "Next window", systemImage: "calendar.badge.clock")
            Spacer()
            Image(systemName: "arrow.right")
              .foregroundStyle(CramlineTheme.accent)
              .accessibilityHidden(true)
          }
          Text(occurrence.startsAt.formatted(date: .abbreviated, time: .shortened))
            .font(.title2.bold())
            .foregroundStyle(CramlineTheme.ink)
          Text("Ends \(occurrence.endsAt.formatted(date: .omitted, time: .shortened))")
            .foregroundStyle(.secondary)
          Text(TimeZone.autoupdatingCurrent.identifier)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
      } else {
        emptyNextSession
      }
    }
  }

  private var emptyNextSession: some View {
    VStack(alignment: .leading, spacing: 10) {
      Image(systemName: "calendar.badge.exclamationmark")
        .font(.title2)
        .foregroundStyle(CramlineTheme.amber)
        .accessibilityHidden(true)
      Text("No upcoming window found").font(.headline)
      Text("Review your local schedule in Plan. You can still begin a one-off session.")
        .font(.callout)
        .foregroundStyle(.secondary)
    }
    .accessibilityElement(children: .combine)
  }

  private var startCard: some View {
    CramlineCard(tint: CramlineTheme.deepEvergreen) {
      VStack(alignment: .leading, spacing: 12) {
        Image(systemName: "bolt.fill")
          .font(.title3)
          .foregroundStyle(CramlineTheme.amber)
          .accessibilityHidden(true)
        Text("Start a one-off session")
          .font(.headline)
          .foregroundStyle(.white)
        Text("Begin a 50-minute session using the targets you selected in Apple’s system picker.")
          .font(.callout)
          .foregroundStyle(.white.opacity(0.75))
        Button {
          CramlineFeedback.impact(.medium)
          actionInFlight = true
          Task {
            await model.startOneOff()
            actionInFlight = false
            if model.currentSession != nil { CramlineFeedback.success() }
          }
        } label: {
          HStack {
            if actionInFlight { ProgressView().tint(CramlineTheme.accent) }
            Text(actionInFlight ? "Starting…" : "Start 50-minute session")
            Spacer()
            Image(systemName: "arrow.right")
          }
        }
        .buttonStyle(CramlineButtonStyle())
        .disabled(actionInFlight)
      }
    }
  }

  private var safetyCard: some View {
    CramlineCard(tint: CramlineTheme.warmSurface, padding: 18) {
      HStack(alignment: .top, spacing: 14) {
        Image(systemName: "hand.raised.fill")
          .font(.title3)
          .foregroundStyle(CramlineTheme.accent)
          .frame(width: 36, height: 36)
          .background(CramlineTheme.accent.opacity(0.10), in: Circle())
          .accessibilityHidden(true)
        VStack(alignment: .leading, spacing: 5) {
          Text("You remain in control").font(.headline)
          Text("Cramline cannot prevent uninstalling or changing Screen Time permission in Settings. It does not read selected-app activity or content.")
            .font(.callout)
            .foregroundStyle(.secondary)
        }
      }
      .accessibilityElement(children: .combine)
    }
  }

  private var sprintFraction: Double {
    guard let sprint = model.activeSprint else { return 0 }
    let total = max(sprint.endDate.timeIntervalSince(sprint.startedAt), 1)
    let elapsed = Date().timeIntervalSince(sprint.startedAt)
    return min(max(elapsed / total, 0), 1)
  }

  private var sprintTimelineText: String {
    guard let sprint = model.activeSprint else { return "No active sprint" }
    let days = max(Calendar.current.dateComponents([.day], from: Date(), to: sprint.endDate).day ?? 0, 0)
    return days == 1 ? "1 calendar day remaining" : "\(days) calendar days remaining"
  }

  private func activeTimingText(_ session: SessionState) -> String {
    if session.state == .paused, let pauseUntil = session.emergencyPauseUntil {
      return "Resume requested around \(pauseUntil.formatted(date: .omitted, time: .shortened))"
    }
    let minutes = max(Int(session.plannedEnd.timeIntervalSince(Date()) / 60), 0)
    return minutes == 1 ? "About 1 minute planned" : "About \(minutes) minutes planned"
  }

  private func actionLabel(_ text: String, icon: String) -> some View {
    HStack {
      if actionInFlight { ProgressView() }
      Text(text)
      Spacer()
      Image(systemName: icon)
    }
  }

  private func stateIcon(_ state: ShieldState) -> String {
    switch state {
    case .active: return "shield.fill"
    case .paused: return "pause.circle.fill"
    case .scheduled: return "calendar.badge.clock"
    case .authorizationNeeded: return "exclamationmark.shield"
    case .ended: return "checkmark.circle"
    case .unknown: return "questionmark.circle"
    }
  }
}
