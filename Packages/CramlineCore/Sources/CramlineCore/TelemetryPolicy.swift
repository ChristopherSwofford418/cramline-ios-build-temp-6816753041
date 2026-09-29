import Foundation

public enum TelemetryEventName: String, CaseIterable, Sendable {
  case telemetryConsentChanged = "telemetry_consent_changed"
  case onboardingCompleted = "onboarding_completed"
  case sprintAction = "sprint_action"
  case screenTimeAuthorizationResult = "screen_time_authorization_result"
  case emergencyAction = "emergency_action"
  case androidBetaAction = "android_beta_action"
  case purchaseFlowAction = "purchase_flow_action"
  case appOperationalError = "app_operational_error"
}

public struct SanitizedTelemetryEvent: Equatable, Sendable {
  public let name: String
  public let properties: [String: String]

  public init(name: String, properties: [String: String]) {
    self.name = name
    self.properties = properties
  }
}

public enum TelemetryPolicyError: Error, Equatable {
  case eventNotAllowed
  case propertyNotAllowed
  case valueNotAllowed
}

public enum TelemetryPolicy {
  private static let allowedValues: [TelemetryEventName: [String: Set<String>]] = [
    .telemetryConsentChanged: ["state": ["enabled", "disabled"]],
    .onboardingCompleted: ["entry": ["rules_planner", "ai_planner"]],
    .sprintAction: [
      "action": [
        "sprint_created", "schedule_created", "session_started", "session_ended",
        "local_data_deleted",
      ]
    ],
    .screenTimeAuthorizationResult: ["result": ["granted", "declined", "revoked"]],
    .emergencyAction: ["action": ["pause_used", "session_ended"]],
    .androidBetaAction: [
      "action": ["companion_opened", "accessibility_beta_enabled", "accessibility_beta_disabled"]
    ],
    .purchaseFlowAction: [
      "action": [
        "plan_viewed", "purchase_started", "purchase_completed", "restore_completed",
        "restore_failed",
      ]
    ],
    .appOperationalError: [
      "category": [
        "authorization", "schedule_registration", "shield_application", "local_storage",
        "purchase", "restore", "ai_unavailable", "configuration",
      ]
    ],
  ]

  public static func sanitize(name: String, properties: [String: String]) throws
    -> SanitizedTelemetryEvent
  {
    guard let event = TelemetryEventName(rawValue: name), let schema = allowedValues[event] else {
      throw TelemetryPolicyError.eventNotAllowed
    }
    guard Set(properties.keys) == Set(schema.keys) else {
      throw TelemetryPolicyError.propertyNotAllowed
    }
    for (key, value) in properties {
      guard schema[key]?.contains(value) == true else {
        throw TelemetryPolicyError.valueNotAllowed
      }
    }
    return SanitizedTelemetryEvent(name: event.rawValue, properties: properties)
  }
}
