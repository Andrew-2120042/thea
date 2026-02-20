import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var storeKit: StoreKitService
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var purchaseError: String?
    @State private var showError = false

    private let features = [
        ("♾️", "Unlimited affirmations"),
        ("🎯", "Personalised to your goals"),
        ("📊", "Advanced streak tracking"),
        ("🌙", "Morning + Night sessions"),
        ("✨", "New affirmations added weekly"),
        ("🔔", "Smart reminders"),
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#1A0533"), Color(hex: "#0D0221"), Color(hex: "#1A0533")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Background stars
            StarsBackground()

            ScrollView {
                VStack(spacing: 0) {
                    // Close button
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(12)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 60)

                    // Hero
                    VStack(spacing: 16) {
                        Text("👑")
                            .font(.system(size: 72))
                            .shadow(color: HypeColors.accent.opacity(0.6), radius: 20)

                        Text("Unlock Your\nFull Potential")
                            .font(.system(size: 36, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Text("You've experienced the power of speaking affirmations out loud. Now go all in.")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 32)

                    // Features list
                    VStack(spacing: 12) {
                        ForEach(features, id: \.0) { feature in
                            HStack(spacing: 12) {
                                Text(feature.0)
                                    .font(.system(size: 20))
                                    .frame(width: 32)
                                Text(feature.1)
                                    .font(.system(size: 15))
                                    .foregroundColor(.white.opacity(0.9))
                                Spacer()
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(HypeColors.primary)
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 24)
                        }
                    }
                    .padding(.bottom, 32)

                    // Products
                    if storeKit.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(40)
                    } else {
                        VStack(spacing: 12) {
                            // Yearly (best value)
                            if let yearly = storeKit.yearlyProduct {
                                ProductCard(
                                    product: yearly,
                                    badge: "BEST VALUE",
                                    perPeriod: "/year",
                                    savings: "Save 50%",
                                    isSelected: selectedProduct?.id == yearly.id
                                ) {
                                    selectedProduct = yearly
                                    HapticManager.selection()
                                }
                            }

                            // Monthly
                            if let monthly = storeKit.monthlyProduct {
                                ProductCard(
                                    product: monthly,
                                    badge: nil,
                                    perPeriod: "/month",
                                    savings: nil,
                                    isSelected: selectedProduct?.id == monthly.id
                                ) {
                                    selectedProduct = monthly
                                    HapticManager.selection()
                                }
                            }

                            // Fallback if no products loaded
                            if storeKit.products.isEmpty {
                                FallbackProductCard(
                                    title: "HYPE Premium",
                                    price: "$4.99/month or $29.99/year",
                                    isSelected: false,
                                    action: {}
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        .onAppear {
                            if let first = storeKit.yearlyProduct ?? storeKit.monthlyProduct {
                                selectedProduct = first
                            }
                        }
                    }

                    // CTA
                    VStack(spacing: 16) {
                        GradientButton(
                            title: isPurchasing ? "Processing..." : "Start my transformation",
                            action: { purchase() },
                            isLoading: isPurchasing,
                            disabled: selectedProduct == nil
                        )
                        .padding(.horizontal, 24)

                        VStack(spacing: 4) {
                            Text("Cancel anytime. No commitments.")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.5))

                            Button("Restore purchases") {
                                Task { await storeKit.restorePurchases() }
                            }
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 60)
                }
            }
        }
        .alert("Purchase Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(purchaseError ?? "Something went wrong. Please try again.")
        }
    }

    private func purchase() {
        guard let product = selectedProduct else { return }
        isPurchasing = true
        HapticManager.impact(.medium)

        Task {
            do {
                let success = try await storeKit.purchase(product)
                if success {
                    HapticManager.successCelebration()
                    dismiss()
                }
            } catch {
                purchaseError = error.localizedDescription
                showError = true
                HapticManager.notification(.error)
            }
            isPurchasing = false
        }
    }
}

// MARK: - Product Card
struct ProductCard: View {
    let product: Product
    let badge: String?
    let perPeriod: String
    let savings: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let badge = badge {
                        Text(badge)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(HypeColors.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(HypeColors.accent.opacity(0.15))
                            .clipShape(Capsule())
                    }

                    Text(product.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    if let savings = savings {
                        Text(savings)
                            .font(.system(size: 13))
                            .foregroundColor(.green)
                    }
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text(product.displayPrice)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    Text(perPeriod)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(20)
            .background(
                isSelected
                    ? HypeColors.primary.opacity(0.25)
                    : Color.white.opacity(0.08)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? HypeColors.primary : Color.white.opacity(0.15),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(GlassButtonStyle())
    }
}

// MARK: - Fallback Product Card
struct FallbackProductCard: View {
    let title: String
    let price: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Text(price)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
            }
            .padding(20)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(GlassButtonStyle())
    }
}

// MARK: - Stars Background
struct StarsBackground: View {
    var body: some View {
        GeometryReader { geo in
            ForEach(0..<60, id: \.self) { _ in
                Circle()
                    .fill(Color.white.opacity(Double.random(in: 0.1...0.5)))
                    .frame(width: Double.random(in: 1...3), height: Double.random(in: 1...3))
                    .position(
                        x: Double.random(in: 0...geo.size.width),
                        y: Double.random(in: 0...geo.size.height)
                    )
            }
        }
    }
}
