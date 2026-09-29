import SwiftUI

struct PrivacyView: View {
  @ObservedObject var model: AppModel
  @State private var showingDeleteConfirmation = false
  @State private var telemetrySaving = false
  @State private var telemetryNotice: String?

  var body: some View {
    ZStack {
      CramlineBackground()
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          pageHeader
          localFirstHero
          analyticsCard
          boundariesCard
          documentsCard
          deleteCard
        }
        .frame(maxWidth: CramlineTheme.contentWidth, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
      }
      .scrollIndicators(.hidden)
    }
    .navigationTitle("Privacy")
    .navigationBarTitleDisplayMode(.inline)
    .confirmationDialog(
      "Delete all local data?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible
    ) {
      Button("Delete all local data", role: .destructive) {
        CramlineFeedback.warning()
        Task { await model.deleteAllLocalData() }
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("This action cannot be undone. Cramline will fail open by removing its shields and schedules first, then delete its local data.")
    }
  }

  private var pageHeader: some View {
    VStack(alignment: .leading, spacing: 7) {
      CramlineEyebrow(text: "CLEAR BY DESIGN")
      Text("Private, local, and deletable.")
        .font(.system(.largeTitle, design: .rounded, weight: .bold))
        .foregroundStyle(CramlineTheme.ink)
      Text("See what stays on this device, choose optional diagnostics, and erase local data at any time.")
        .foregroundStyle(.secondary)
    }
  }

  private var localFirstHero: some View {
    CramlineCard(tint: CramlineTheme.deepEvergreen) {
      HStack(alignment: .center, spacing: 18) {
        Image(systemName: "lock.shield.fill")
          .font(.system(size: 32, weight: .semibold))
          .foregroundStyle(CramlineTheme.amber)
          .frame(width: 66, height: 66)
          .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 20))
          .accessibilityHidden(true)
        VStack(alignment: .leading, spacing: 5) {
          Text("Your plan lives here").font(.title3.bold()).foregroundStyle(.white)
          Text("No Cramline account is required. Apple picker choices remain opaque system tokens.")
            .font(.callout)
            .foregroundStyle(.white.opacity(0.76))
        }
      }
      .accessibilityElement(children: .combine)
    }
  }

  private var analyticsCard: some View {
    CramlineCard {
      VStack(alignment: .leading, spacing: 16) {
        sectionHeader("Analytics and crash information", icon: "waveform.path.ecg")
        Text(TelemetryController.consentCopy)
          .font(.callout)
          .foregroundStyle(.secondary)
        Toggle(
          "Share anonymous usage and crash information",
          isOn: Binding(
            get: { model.persisted.privacy.telemetryConsent == .enabled },
            set: { value in
              telemetrySaving = true
              telemetryNotice = nil
              Task {
                await model.setTelemetry(value)
                telemetrySaving = false
                telemetryNotice = value ? "Optional diagnostics enabled." : "Optional diagnostics disabled."
                CramlineFeedback.success()
              }
            }
          )
        )
        .font(.headline)
        .tint(CramlineTheme.accent)
        .disabled(telemetrySaving)
        if telemetrySaving {
          Label("Saving preference…", systemImage: "clock")
            .font(.callout)
            .foregroundStyle(.secondary)
        } else if let telemetryNotice {
          Label(telemetryNotice, systemImage: "checkmark.circle.fill")
            .font(.callout.weight(.semibold))
            .foregroundStyle(CramlineTheme.success)
        }
      }
    }
  }

  private var boundariesCard: some View {
    CramlineCard(tint: CramlineTheme.warmSurface) {
      VStack(alignment: .leading, spacing: 16) {
        sectionHeader("Data boundaries", icon: "hand.raised.fill")
        PrivacyBoundaryRow(icon: "iphone", title: "Stored locally", text: "Selected Apple tokens stay in protected local app-group storage.")
        Divider()
        PrivacyBoundaryRow(icon: "eye.slash", title: "Not observed", text: "Cramline does not read app content, messages, feeds, browser history, or device activity.")
        Divider()
        PrivacyBoundaryRow(icon: "person.crop.circle.badge.xmark", title: "No profile required", text: "No account, advertising ID, exam provider, school, or employer is required.")
        Divider()
        PrivacyBoundaryRow(
          icon: AppEnvironment.isPremiumOfferAvailable ? "cpu" : "cpu.fill",
          title: AppEnvironment.isPremiumOfferAvailable ? "AI only after review" : "AI unavailable in this build",
          text: AppEnvironment.isPremiumOfferAvailable
            ? "AI receives only the planning fields you review and approve for that request."
            : "No planning request is sent to an AI service because no endpoint is configured."
        )
      }
    }
  }

  private var documentsCard: some View {
    CramlineCard {
      VStack(alignment: .leading, spacing: 14) {
        sectionHeader("Documents and support", icon: "doc.text.fill")
        documentRow("Privacy policy", url: AppEnvironment.privacyURL, unavailable: "Privacy policy is not yet published for this build.")
        documentRow("Support", url: AppEnvironment.supportURL, unavailable: "Support contact is not yet published for this build.")
        documentRow("Terms", url: AppEnvironment.termsURL, unavailable: "Terms are not yet published for this build.")
      }
    }
  }

  private var deleteCard: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(alignment: .top, spacing: 12) {
        Image(systemName: "trash.fill")
          .foregroundStyle(CramlineTheme.danger)
          .frame(width: 38, height: 38)
          .background(CramlineTheme.danger.opacity(0.10), in: Circle())
          .accessibilityHidden(true)
        VStack(alignment: .leading, spacing: 4) {
          Text("Delete local data").font(.title3.bold())
          Text("This removes your sprint, schedules, opaque tokens, plans, reflections, diagnostics identifier, and Cramline shields from this device.")
            .font(.callout)
            .foregroundStyle(.secondary)
        }
      }
      Button("Delete all local \(AppEnvironment.appName) data", role: .destructive) {
        CramlineFeedback.warning()
        showingDeleteConfirmation = true
      }
      .buttonStyle(.bordered)
      .controlSize(.large)
      .frame(maxWidth: .infinity)
      .accessibilityHint("Opens a confirmation before removing Cramline controls and local data")
    }
    .padding(20)
    .background(CramlineTheme.danger.opacity(0.06), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    .overlay(RoundedRectangle(cornerRadius: 24).stroke(CramlineTheme.danger.opacity(0.15)))
  }

  private func sectionHeader(_ title: String, icon: String) -> some View {
    Label(title, systemImage: icon)
      .font(.title3.bold())
      .foregroundStyle(CramlineTheme.ink)
  }

  @ViewBuilder
  private func documentRow(_ title: String, url: URL?, unavailable: String) -> some View {
    if let url {
      Link(destination: url) {
        HStack {
          Text(title).font(.headline)
          Spacer()
          Image(systemName: "arrow.up.right")
        }
        .padding()
        .background(CramlineTheme.warmSurface, in: RoundedRectangle(cornerRadius: 14))
      }
    } else {
      HStack(alignment: .top, spacing: 12) {
        Image(systemName: "clock.badge.exclamationmark").foregroundStyle(.secondary)
        VStack(alignment: .leading, spacing: 3) {
          Text(title).font(.headline)
          Text(unavailable).font(.callout).foregroundStyle(.secondary)
        }
      }
      .padding()
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Color.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
      .accessibilityElement(children: .combine)
    }
  }
}

private struct PrivacyBoundaryRow: View {
  let icon: String
  let title: String
  let text: String

  var body: some View {
    HStack(alignment: .top, spacing: 13) {
      Image(systemName: icon)
        .font(.headline)
        .foregroundStyle(CramlineTheme.accent)
        .frame(width: 34)
        .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 4) {
        Text(title).font(.headline)
        Text(text).font(.callout).foregroundStyle(.secondary)
      }
    }
    .accessibilityElement(children: .combine)
  }
}
