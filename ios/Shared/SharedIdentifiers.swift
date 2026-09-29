import DeviceActivity
import Foundation
import ManagedSettings

public enum SharedIdentifiers {
  public static let appName: String = {
    guard let value = Bundle.main.object(forInfoDictionaryKey: "CRAMLINE_APP_NAME") as? String,
      !value.isEmpty,
      !value.contains("$(")
    else {
      return "Cramline Exam Sprint"
    }
    return value
  }()

  public static let appGroupIdentifier: String = {
    guard let value = Bundle.main.object(forInfoDictionaryKey: "CRAMLINE_APP_GROUP") as? String,
      !value.isEmpty,
      !value.contains("$(")
    else {
      return "group.com.clearpasstechnologies.cramline.shared"
    }
    return value
  }()
}

extension ManagedSettingsStore.Name {
  static let cramline = Self("cramline")
}

extension DeviceActivityName {
  static func oneOff(_ id: UUID) -> Self { Self("cramline.oneoff.\(id.uuidString)") }
  static func pauseResume(_ id: UUID) -> Self { Self("cramline.pause-resume.\(id.uuidString)") }
}
