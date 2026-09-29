import Foundation

public enum AppEnvironment {
  public static let appName = value("CRAMLINE_APP_NAME", fallback: "Cramline Exam Sprint")
  public static let subtitle = value(
    "CRAMLINE_APP_SUBTITLE", fallback: "Study Focus & App Shield")
  public static let supportURL = publicHTTPSURL("CRAMLINE_SUPPORT_URL")
  public static let privacyURL = publicHTTPSURL("CRAMLINE_PRIVACY_URL")
  public static let termsURL = publicHTTPSURL("CRAMLINE_TERMS_URL")
  public static let manageSubscriptionsURL = URL(string: "https://apps.apple.com/account/subscriptions")!
  public static let premiumProductIdentifiers = [
    value(
      "CRAMLINE_PREMIUM_MONTHLY_PRODUCT_ID",
      fallback: "com.clearpasstechnologies.cramline.premium.monthly")
  ]
  public static let maximumSelectedApplications = 50

  public static var aiBaseURL: URL? { publicHTTPSURL("CRAMLINE_AI_BASE_URL") }
  public static var mixpanelToken: String? { optionalValue("CRAMLINE_MIXPANEL_TOKEN") }
  public static var isPremiumOfferAvailable: Bool {
    aiBaseURL != nil && !premiumProductIdentifiers.isEmpty
  }

  private static func value(_ key: String, fallback: String) -> String {
    optionalValue(key) ?? fallback
  }

  private static func publicHTTPSURL(_ key: String) -> URL? {
    guard
      let value = optionalValue(key),
      let url = URL(string: value),
      url.scheme?.lowercased() == "https",
      let host = url.host?.lowercased(),
      host != "example.com",
      !host.hasSuffix(".example.com")
    else { return nil }
    return url
  }

  private static func optionalValue(_ key: String) -> String? {
    guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
      !value.isEmpty,
      !value.contains("$(")
    else { return nil }
    return value
  }
}
