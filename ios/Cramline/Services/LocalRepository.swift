import CramlineCore
import Foundation

struct PersistedAppState: Codable, Equatable {
  var sprint: Sprint?
  var windows: [StudyWindow]
  var sessions: [SessionState]
  var plans: [LocalPlan]
  var reflections: [LocalReflection]
  var privacy: PrivacySettings
  var onboardingComplete: Bool

  static let empty = PersistedAppState(
    sprint: nil,
    windows: [],
    sessions: [],
    plans: [],
    reflections: [],
    privacy: PrivacySettings(),
    onboardingComplete: false
  )
}

actor LocalRepository {
  private let fileManager: FileManager
  private let encoder: JSONEncoder
  private let decoder: JSONDecoder
  private let fileURL: URL

  init(fileManager: FileManager = .default) {
    self.fileManager = fileManager
    encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    let directory = base.appendingPathComponent("Cramline", isDirectory: true)
    try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    fileURL = directory.appendingPathComponent("local-state.json")
  }

  func load() -> PersistedAppState {
    guard let data = try? Data(contentsOf: fileURL),
      let state = try? decoder.decode(PersistedAppState.self, from: data)
    else {
      return .empty
    }
    return state
  }

  func save(_ state: PersistedAppState) throws {
    let data = try encoder.encode(state)
    try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUnlessOpen])
  }

  func deleteAll() throws {
    if fileManager.fileExists(atPath: fileURL.path) {
      try fileManager.removeItem(at: fileURL)
    }
    SharedScreenTimeState.shared.clearAll()
  }
}
