import StoreKit
import SwiftUI

struct PremiumView: View {
  @ObservedObject var model: AppModel
  @ObservedObject private var purchases: PurchaseController

  init(model: AppModel) {
    self.model = model
    self.purchases = model.purchases
  }

  var body: some View {
    ZStack {
      CramlineBackground()
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          pageHeader
          premiumHero
          freeFoundation
          offerCard
        }
        .frame(maxWidth: CramlineTheme.contentWidth, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
      }
      .scrollIndicators(.hidden)
    }
    .navigationTitle("Premium")
    .navigationBarTitleDisplayMode(.inline)
  }

  private var pageHeader: some View {
    VStack(alignment: .leading, spacing: 7) {
      CramlineEyebrow(text: "OPTIONAL, NEVER REQUIRED")
      Text("Core focus stays free.")
        .font(.system(.largeTitle, design: .rounded, weight: .bold))
        .foregroundStyle(CramlineTheme.ink)
      Text("A purchase is never required to schedule, pause, end, plan offline, or delete your local data.")
        .foregroundStyle(.secondary)
    }
  }

  private var premiumHero: some View {
    CramlineCard(tint: CramlineTheme.deepEvergreen) {
      VStack(alignment: .leading, spacing: 16) {
        HStack {
          Image(systemName: AppEnvironment.isPremiumOfferAvailable ? "sparkles" : "sparkles.slash.fill")
            .font(.system(size: 30, weight: .semibold))
            .foregroundStyle(CramlineTheme.amber)
            .frame(width: 62, height: 62)
            .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 20))
            .accessibilityHidden(true)
          Spacer()
          CramlineStatusPill(
            title: AppEnvironment.isPremiumOfferAvailable ? "Optional" : "Not configured",
            systemImage: AppEnvironment.isPremiumOfferAvailable ? "checkmark" : "minus.circle",
            tint: AppEnvironment.isPremiumOfferAvailable ? CramlineTheme.amber : .white.opacity(0.82))
        }
        Text(AppEnvironment.isPremiumOfferAvailable ? "Optional AI planning drafts" : "No Premium offer in this build")
          .font(.title2.bold())
          .foregroundStyle(.white)
        Text(
          AppEnvironment.isPremiumOfferAvailable
            ? "Adds optional AI planning drafts only after you review and approve the fields sent for each request."
            : "Premium and AI services are unavailable because this build has no configured AI endpoint. The complete on-device planner remains ready to use."
        )
        .foregroundStyle(.white.opacity(0.78))
      }
    }
  }

  private var freeFoundation: some View {
    CramlineCard(tint: CramlineTheme.warmSurface) {
      VStack(alignment: .leading, spacing: 15) {
        Text("Always included").font(.title3.bold())
        includedRow("Apple Screen Time shield requests", icon: "shield.fill")
        includedRow("Local schedules and one-off sessions", icon: "calendar.badge.clock")
        includedRow("Emergency pause and session end", icon: "hand.raised.fill")
        includedRow("Offline weekly planning drafts", icon: "wifi.slash")
        includedRow("Local data deletion", icon: "trash")
      }
    }
  }

  private var offerCard: some View {
    CramlineCard {
      VStack(alignment: .leading, spacing: 16) {
        Label("Subscription", systemImage: "creditcard.fill")
          .font(.title3.bold())
          .foregroundStyle(CramlineTheme.ink)
        if !AppEnvironment.isPremiumOfferAvailable {
          unavailableOffer
        } else if purchases.isLoading {
          loadingOffer
        } else if purchases.products.isEmpty {
          emptyOffer
        } else {
          ForEach(purchases.products) { product in
            productCard(product)
          }
        }

        if AppEnvironment.isPremiumOfferAvailable {
          Divider()
          Button {
            CramlineFeedback.impact()
            Task {
              await purchases.restorePurchases()
              if purchases.userFacingError == nil { CramlineFeedback.success() }
            }
          } label: {
            HStack {
              if purchases.isLoading { ProgressView() }
              Text(purchases.isLoading ? "Checking purchases…" : "Restore Purchases")
            }
          }
          .buttonStyle(CramlineButtonStyle())
          .disabled(purchases.isLoading)
          Link("Manage subscriptions", destination: AppEnvironment.manageSubscriptionsURL)
            .font(.headline)
            .frame(maxWidth: .infinity)
          if let error = purchases.userFacingError {
            Label(error, systemImage: "exclamationmark.triangle.fill")
              .font(.callout)
              .foregroundStyle(CramlineTheme.danger)
              .padding()
              .frame(maxWidth: .infinity, alignment: .leading)
              .background(CramlineTheme.danger.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
          }
        }
      }
    }
  }

  private var unavailableOffer: some View {
    HStack(alignment: .top, spacing: 13) {
      Image(systemName: "clock.badge.exclamationmark")
        .font(.title2)
        .foregroundStyle(.secondary)
        .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 5) {
        Text("No subscription offer is available in this build.")
          .font(.headline)
        Text("There is nothing to buy or restore. Use the free on-device planner from the Plan tab.")
          .font(.callout)
          .foregroundStyle(.secondary)
      }
    }
    .padding()
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
    .accessibilityElement(children: .combine)
  }

  private var loadingOffer: some View {
    HStack(spacing: 13) {
      ProgressView().tint(CramlineTheme.accent)
      VStack(alignment: .leading, spacing: 3) {
        Text("Loading App Store details…").font(.headline)
        Text("No purchase can begin until localized price and renewal terms are available.")
          .font(.callout)
          .foregroundStyle(.secondary)
      }
    }
    .padding()
    .accessibilityElement(children: .combine)
  }

  private var emptyOffer: some View {
    Label {
      VStack(alignment: .leading, spacing: 4) {
        Text("App Store details unavailable").font(.headline)
        Text("Price and renewal details are unavailable until App Store products are configured. Try again later; free features are unaffected.")
          .font(.callout)
          .foregroundStyle(.secondary)
      }
    } icon: {
      Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(CramlineTheme.amber)
    }
    .padding()
    .background(CramlineTheme.amber.opacity(0.09), in: RoundedRectangle(cornerRadius: 16))
    .accessibilityElement(children: .combine)
  }

  private func productCard(_ product: Product) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .firstTextBaseline) {
        Text(product.displayName).font(.title3.bold())
        Spacer()
        Text(product.displayPrice).font(.title2.bold()).foregroundStyle(CramlineTheme.accent)
      }
      Text(product.description).font(.callout).foregroundStyle(.secondary)
      if let subscription = product.subscription {
        Text("Renews every \(subscription.subscriptionPeriod.value) \(periodName(subscription.subscriptionPeriod.unit)) until cancelled in App Store settings.")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
      Button("Subscribe") {
        CramlineFeedback.impact(.medium)
        Task {
          await purchases.purchase(product)
          if purchases.userFacingError == nil { CramlineFeedback.success() }
        }
      }
      .buttonStyle(CramlineButtonStyle(prominent: true))
      .disabled(purchases.isLoading)
    }
    .padding()
    .background(CramlineTheme.warmSurface, in: RoundedRectangle(cornerRadius: 18))
  }

  private func includedRow(_ title: String, icon: String) -> some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .foregroundStyle(CramlineTheme.success)
        .frame(width: 30, height: 30)
        .background(CramlineTheme.success.opacity(0.10), in: Circle())
        .accessibilityHidden(true)
      Text(title).font(.callout.weight(.semibold))
      Spacer(minLength: 0)
      Image(systemName: "checkmark").font(.caption.bold()).foregroundStyle(CramlineTheme.success)
        .accessibilityHidden(true)
    }
    .accessibilityElement(children: .combine)
  }

  private func periodName(_ unit: Product.SubscriptionPeriod.Unit) -> String {
    switch unit {
    case .day: return "day(s)"
    case .week: return "week(s)"
    case .month: return "month(s)"
    case .year: return "year(s)"
    @unknown default: return "period"
    }
  }
}
