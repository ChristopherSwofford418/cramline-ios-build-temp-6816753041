import Combine
import CramlineCore
import FirebaseAnalytics
import FirebaseCore
import FirebaseCrashlytics
import Foundation
import Mixpanel

@MainActor
final class TelemetryController: ObservableObject {
  static let shared = TelemetryController()

  static let consentCopy =
    "Help improve \(AppEnvironment.appName) with anonymous usage and crash information. We never send selected apps, app activity, social content, messages, browser history, your exact schedule, exam details, reflections, or identity. Saying no does not change your study shield."

  @Published private(set) var isEnabled = false

  private var firebaseConfigured = false
  private var mixpanel: MixpanelInstance?
  private let analyticsIDKey = "telemetry.analyticsInstallationID"
  private let analyticsIDCreatedAtKey = "telemetry.analyticsInstallationID.createdAt"
  private var firebaseAutomaticEventsApproved: Bool {
    let value = Bundle.main.object(
      forInfoDictionaryKey: "CRAMLINE_FIREBASE_ANALYTICS_ALLOW_AUTOMATIC_EVENTS")
    if let boolean = value as? Bool { return boolean }
    return (value as? String)?.uppercased() == "YES"
  }

  private init() {}

  func bootstrap(consent: PrivacySettings.ConsentState) {
    configureFirebaseIfAvailable()
    apply(consent: consent)
  }

  func apply(consent: PrivacySettings.ConsentState) {
    let enable = consent == .enabled
    isEnabled = enable
    if firebaseConfigured {
      // Firebase Analytics emits vendor automatic events when enabled. Keep it disabled
      // unless the exact release archive's event inventory has been accepted.
      Analytics.setAnalyticsCollectionEnabled(enable && firebaseAutomaticEventsApproved)
      Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(enable)
    }

    if enable {
      initializeMixpanelAfterConsent()
    } else {
      mixpanel?.optOutTracking()
      mixpanel?.reset()
      mixpanel = nil
      if firebaseConfigured {
        Analytics.resetAnalyticsData()
        Crashlytics.crashlytics().deleteUnsentReports()
      }
      UserDefaults.standard.removeObject(forKey: analyticsIDKey)
      UserDefaults.standard.removeObject(forKey: analyticsIDCreatedAtKey)
    }
  }

  func track(_ name: TelemetryEventName, properties: [String: String]) {
    guard isEnabled,
      let event = try? TelemetryPolicy.sanitize(name: name.rawValue, properties: properties)
    else { return }
    let firebaseProperties = event.properties.reduce(into: [String: Any]()) {
      $0[$1.key] = $1.value
    }
    if firebaseConfigured && firebaseAutomaticEventsApproved {
      Analytics.logEvent(event.name, parameters: firebaseProperties)
    }
    let mixpanelProperties: Properties = event.properties.reduce(into: [:]) { result, item in
      result[item.key] = item.value
    }
    mixpanel?.track(event: event.name, properties: mixpanelProperties)
  }

  private func configureFirebaseIfAvailable() {
    guard !firebaseConfigured else { return }
    guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
      return
    }
    FirebaseApp.configure()
    firebaseConfigured = true
    Analytics.setAnalyticsCollectionEnabled(false)
    Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(false)
  }

  private func initializeMixpanelAfterConsent() {
    guard mixpanel == nil, let token = AppEnvironment.mixpanelToken else { return }
    let installationID: String
    let createdAt = UserDefaults.standard.object(forKey: analyticsIDCreatedAtKey) as? Date
    let rotationDue = createdAt.map { Date().timeIntervalSince($0) >= 30 * 86_400 } ?? true
    if !rotationDue, let existing = UserDefaults.standard.string(forKey: analyticsIDKey) {
      installationID = existing
    } else {
      installationID = UUID().uuidString
      UserDefaults.standard.set(installationID, forKey: analyticsIDKey)
      UserDefaults.standard.set(Date(), forKey: analyticsIDCreatedAtKey)
    }

    let options = MixpanelOptions(
      token: token,
      flushInterval: 60,
      trackAutomaticEvents: false,
      optOutTrackingByDefault: false,
      useUniqueDistinctId: false,
      deviceIdProvider: { installationID },
      featureFlagOptions: FeatureFlagOptions(enabled: false)
    )
    mixpanel = Mixpanel.initialize(options: options)
    mixpanel?.useIPAddressForGeoLocation = false
    mixpanel?.loggingEnabled = false
  }
}
