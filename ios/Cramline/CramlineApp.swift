import SwiftUI
import UIKit

@main
struct CramlineApp: App {
  @StateObject private var model = AppModel()
  @Environment(\.scenePhase) private var scenePhase

  var body: some Scene {
    WindowGroup {
      Group {
        if !model.isLoaded {
          CramlineLoadingView()
        } else if model.persisted.onboardingComplete {
          MainTabView(model: model)
        } else {
          OnboardingView(model: model)
        }
      }
      .tint(CramlineTheme.accent)
      .alert(
        AppEnvironment.appName,
        isPresented: Binding(
          get: { model.alertMessage != nil },
          set: { if !$0 { model.alertMessage = nil } }
        )
      ) {
        Button("OK", role: .cancel) { model.alertMessage = nil }
      } message: {
        Text(model.alertMessage ?? "")
      }
      .onChange(of: scenePhase) { phase in
        if phase == .active {
          Task { await model.applicationDidBecomeActive() }
        }
      }
    }
  }
}

enum CramlineTheme {
  static let accent = Color(red: 0.10, green: 0.35, blue: 0.28)
  static let accentBright = Color(red: 0.20, green: 0.53, blue: 0.40)
  static let deepEvergreen = Color(red: 0.025, green: 0.15, blue: 0.12)
  static let ink = Color(red: 0.07, green: 0.13, blue: 0.11)
  static let canvas = Color(red: 0.98, green: 0.965, blue: 0.92)
  static let warmSurface = Color(red: 0.95, green: 0.93, blue: 0.86)
  static let amber = Color(red: 0.97, green: 0.64, blue: 0.17)
  static let success = Color(red: 0.12, green: 0.48, blue: 0.31)
  static let danger = Color(red: 0.70, green: 0.19, blue: 0.16)
  static let contentWidth: CGFloat = 760
  static let wideContentWidth: CGFloat = 960
}

@MainActor
enum CramlineFeedback {
  static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .soft) {
    UIImpactFeedbackGenerator(style: style).impactOccurred()
  }

  static func success() {
    UINotificationFeedbackGenerator().notificationOccurred(.success)
  }

  static func warning() {
    UINotificationFeedbackGenerator().notificationOccurred(.warning)
  }
}

struct MainTabView: View {
  @ObservedObject var model: AppModel

  var body: some View {
    TabView {
      NavigationStack { HomeView(model: model) }
        .tabItem { Label("Today", systemImage: "timer") }
      NavigationStack { PlannerView(model: model) }
        .tabItem { Label("Plan", systemImage: "calendar") }
      NavigationStack { PrivacyView(model: model) }
        .tabItem { Label("Privacy", systemImage: "hand.raised") }
      NavigationStack { PremiumView(model: model) }
        .tabItem { Label("Premium", systemImage: "sparkles") }
    }
    .toolbarBackground(.visible, for: .tabBar)
    .toolbarBackground(CramlineTheme.canvas.opacity(0.96), for: .tabBar)
  }
}

struct CramlineBackground: View {
  var body: some View {
    ZStack {
      CramlineTheme.canvas
      Circle()
        .fill(CramlineTheme.amber.opacity(0.12))
        .frame(width: 360, height: 360)
        .blur(radius: 18)
        .offset(x: 170, y: -310)
      Circle()
        .fill(CramlineTheme.accent.opacity(0.10))
        .frame(width: 420, height: 420)
        .blur(radius: 24)
        .offset(x: -220, y: 330)
    }
    .ignoresSafeArea()
    .accessibilityHidden(true)
  }
}

struct CramlineCard<Content: View>: View {
  var tint: Color = .white
  var padding: CGFloat = 20
  @ViewBuilder var content: Content

  var body: some View {
    content
      .padding(padding)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(tint.opacity(0.94), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 24, style: .continuous)
          .stroke(.white.opacity(0.65), lineWidth: 1)
      )
      .shadow(color: CramlineTheme.deepEvergreen.opacity(0.08), radius: 18, y: 8)
  }
}

struct CramlineEyebrow: View {
  let text: String
  var color: Color = CramlineTheme.accent

  var body: some View {
    Text(text.uppercased())
      .font(.caption.weight(.bold))
      .tracking(1.35)
      .foregroundStyle(color)
      .accessibilityAddTraits(.isHeader)
  }
}

struct CramlineStatusPill: View {
  let title: String
  let systemImage: String
  var tint: Color = CramlineTheme.accent

  var body: some View {
    Label(title, systemImage: systemImage)
      .font(.caption.weight(.semibold))
      .foregroundStyle(tint)
      .padding(.horizontal, 11)
      .padding(.vertical, 7)
      .background(tint.opacity(0.11), in: Capsule())
      .accessibilityElement(children: .combine)
  }
}

struct CramlineButtonStyle: ButtonStyle {
  var prominent = false

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.headline)
      .foregroundStyle(prominent ? Color.white : CramlineTheme.accent)
      .frame(maxWidth: .infinity)
      .padding(.horizontal, 18)
      .padding(.vertical, 14)
      .background(
        prominent ? CramlineTheme.accent : Color.white.opacity(0.72),
        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .stroke(CramlineTheme.accent.opacity(prominent ? 0 : 0.20), lineWidth: 1)
      )
      .scaleEffect(configuration.isPressed ? 0.975 : 1)
      .opacity(configuration.isPressed ? 0.86 : 1)
      .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
  }
}

struct CramlineLoadingView: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var breathing = false

  var body: some View {
    ZStack {
      CramlineBackground()
      VStack(spacing: 18) {
        Image(systemName: "book.pages.fill")
          .font(.system(size: 34, weight: .semibold))
          .foregroundStyle(CramlineTheme.amber)
          .frame(width: 76, height: 76)
          .background(CramlineTheme.deepEvergreen, in: RoundedRectangle(cornerRadius: 22))
          .scaleEffect(breathing ? 1.04 : 0.96)
        Text(AppEnvironment.appName)
          .font(.title2.bold())
          .foregroundStyle(CramlineTheme.ink)
        ProgressView()
          .tint(CramlineTheme.accent)
          .accessibilityLabel("Loading \(AppEnvironment.appName)")
      }
    }
    .onAppear {
      guard !reduceMotion else { return }
      withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
        breathing = true
      }
    }
  }
}
