import FamilyControls
import ManagedSettings
import ManagedSettingsUI
import UIKit

final class ShieldConfigurationExtension: ShieldConfigurationDataSource {
  override func configuration(shielding application: Application) -> ShieldConfiguration {
    configuration()
  }
  override func configuration(shielding application: Application, in category: ActivityCategory)
    -> ShieldConfiguration
  { configuration() }
  override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
    configuration()
  }
  override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory)
    -> ShieldConfiguration
  { configuration() }

  private func configuration() -> ShieldConfiguration {
    let snapshot = SharedScreenTimeState.shared.loadSession()
    let endText = snapshot.map { Self.timeFormatter.string(from: $0.plannedEnd) }
    let title =
      endText.map {
        "This app is paused until \($0) for your \(SharedIdentifiers.appName) study session."
      }
      ?? "This app is paused for your \(SharedIdentifiers.appName) study session."

    return ShieldConfiguration(
      backgroundBlurStyle: .systemThinMaterial,
      backgroundColor: .systemBackground,
      icon: UIImage(systemName: "book.closed.fill"),
      title: ShieldConfiguration.Label(text: title, color: .label),
      subtitle: ShieldConfiguration.Label(text: "You remain in control.", color: .secondaryLabel),
      primaryButtonLabel: ShieldConfiguration.Label(text: "Return to study", color: .white),
      primaryButtonBackgroundColor: UIColor(red: 0.11, green: 0.34, blue: 0.29, alpha: 1),
      secondaryButtonLabel: ShieldConfiguration.Label(
        text: "Emergency pause — 15 minutes", color: .label)
    )
  }

  private static let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    formatter.dateStyle = .none
    formatter.timeZone = .autoupdatingCurrent
    return formatter
  }()
}
