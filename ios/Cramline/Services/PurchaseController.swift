import Combine
import CramlineCore
import Foundation
import StoreKit

@MainActor
final class PurchaseController: ObservableObject {
  @Published private(set) var products: [Product] = []
  @Published private(set) var hasPremium = false
  @Published private(set) var isLoading = false
  @Published var userFacingError: String?

  private var updatesTask: Task<Void, Never>?

  init() {
    guard AppEnvironment.isPremiumOfferAvailable else { return }
    updatesTask = observeTransactions()
    Task {
      await refreshProducts()
      await refreshEntitlements()
    }
  }

  deinit { updatesTask?.cancel() }

  func refreshProducts() async {
    guard AppEnvironment.isPremiumOfferAvailable else {
      products = []
      isLoading = false
      return
    }
    isLoading = true
    defer { isLoading = false }
    do {
      products = try await Product.products(for: AppEnvironment.premiumProductIdentifiers)
    } catch {
      userFacingError =
        "Premium details are temporarily unavailable. The free study shield still works."
    }
  }

  func purchase(_ product: Product) async {
    guard AppEnvironment.isPremiumOfferAvailable else {
      userFacingError = "No premium offer is configured in this build."
      return
    }
    TelemetryController.shared.track(
      .purchaseFlowAction, properties: ["action": "purchase_started"])
    do {
      let result = try await product.purchase()
      switch result {
      case let .success(verification):
        let transaction = try verified(verification)
        await transaction.finish()
        await refreshEntitlements()
        TelemetryController.shared.track(
          .purchaseFlowAction, properties: ["action": "purchase_completed"])
      case .pending:
        userFacingError = "The purchase is pending approval in the App Store."
      case .userCancelled:
        break
      @unknown default:
        userFacingError = "The App Store returned an unknown purchase state."
      }
    } catch {
      userFacingError = "The purchase could not be completed. Your free shield remains available."
    }
  }

  func restorePurchases() async {
    do {
      try await AppStore.sync()
      await refreshEntitlements()
      TelemetryController.shared.track(
        .purchaseFlowAction, properties: ["action": "restore_completed"])
    } catch {
      userFacingError = "Purchases could not be restored right now. Please try again later."
      TelemetryController.shared.track(
        .purchaseFlowAction, properties: ["action": "restore_failed"])
    }
  }

  func refreshEntitlements() async {
    var active = false
    for await result in Transaction.currentEntitlements {
      guard let transaction = try? verified(result) else { continue }
      if AppEnvironment.premiumProductIdentifiers.contains(transaction.productID),
        transaction.revocationDate == nil,
        transaction.expirationDate.map({ $0 > Date() }) ?? true
      {
        active = true
      }
    }
    hasPremium = active
  }

  private func observeTransactions() -> Task<Void, Never> {
    Task(priority: .background) { [weak self] in
      for await result in Transaction.updates {
        guard let self, let transaction = try? self.verified(result) else { continue }
        await transaction.finish()
        await self.refreshEntitlements()
      }
    }
  }

  private func verified<T>(_ result: VerificationResult<T>) throws -> T {
    switch result {
    case let .verified(value): return value
    case .unverified: throw StoreKitError.failedVerification
    }
  }
}

enum StoreKitError: Error { case failedVerification }
