//
//  OnboardingView.swift
//  Budget Control
//
//  First-launch intro. A 4-screen paged walkthrough with a custom dot
//  indicator and CTA. Completing it sets hasOnboarded = true upstream,
//  which flips ContentView over to MainTabView.
//

import SwiftUI

struct OnboardingView: View {
    /// Called when onboarding completes (sets hasOnboarded = true upstream).
    var onFinish: () -> Void

    @State private var currentPage = 0

    private struct Page: Identifiable {
        let id = UUID()
        let symbol: String
        let pastel: PastelStyle
        let title: String
        let body: String
    }

    private let pages: [Page] = [
        Page(
            symbol: "target",
            pastel: .peach,
            title: "Take control of your money",
            body: "Track spending, set budgets, and reach your goals — all in one simple app."
        ),
        Page(
            symbol: "creditcard.fill",
            pastel: .sky,
            title: "All your wallets in one place",
            body: "Cash, card, savings — track each separately and see your total balance at a glance."
        ),
        Page(
            symbol: "airplane",
            pastel: .mint,
            title: "Built for life on the go",
            body: "Switch currencies anytime. Use Trip mode to tag expenses per journey automatically."
        ),
        Page(
            symbol: "lock.fill",
            pastel: .lavender,
            title: "Your data stays with you",
            body: "No accounts, no servers, no tracking. Everything lives on your device."
        ),
    ]

    private var isLastPage: Bool { currentPage == pages.count - 1 }

    var body: some View {
        ZStack {
            AppTheme.Colors.background.ignoresSafeArea()

            AmbientBackground(color: pages[currentPage].pastel.fill)
                .allowsHitTesting(false)

            VStack(spacing: AppTheme.Spacing.lg) {
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        pageContent(page, index: index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                pageIndicator

                // CTA + Skip are grouped tightly so they read as one pair
                // rather than two disconnected controls.
                VStack(spacing: AppTheme.Spacing.sm) {
                    ctaButton

                    skipButton
                        .opacity(currentPage == 0 ? 0 : 1)
                        .disabled(currentPage == 0)
                }
            }
            .padding(.bottom, AppTheme.Spacing.lg)
        }
        .onChange(of: currentPage) { _, _ in
            HapticManager.light()
        }
    }

    // MARK: - Page Content

    private func pageContent(_ page: Page, index: Int) -> some View {
        let isCurrent = index == currentPage

        return VStack(spacing: AppTheme.Spacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [page.pastel.fill, page.pastel.fill.opacity(0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 140
                        )
                    )
                    .frame(width: 280, height: 280)
                    .blur(radius: 30)
                    .opacity(glowOpacity(for: page.pastel))

                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(page.pastel.badge)
                    .frame(width: 120, height: 120)
                    .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 8)
                    .overlay {
                        Image(systemName: page.symbol)
                            .font(.system(size: 120 * 0.4, weight: .semibold))
                            .foregroundStyle(page.pastel.text)
                    }
            }
            .scaleEffect(isCurrent ? 1.0 : 0.85)
            .opacity(isCurrent ? 1.0 : 0.0)
            .animation(.spring(response: 0.45, dampingFraction: 0.7), value: currentPage)

            Text(page.title)
                .font(.appSans(AppTheme.Typography.fontTitle, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)

            Text(page.body)
                .font(.appSans(AppTheme.Typography.fontBody))
                .foregroundStyle(AppTheme.Colors.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.lg)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    /// Peach and lavender read weaker than sky and mint against
    /// `AppTheme.background` at the same alpha, so their glow gets an
    /// opacity boost so all 4 pages feel equally rich.
    private func glowOpacity(for pastel: PastelStyle) -> Double {
        switch pastel {
        case .peach, .lavender: return 1.6
        default: return 1.0
        }
    }

    // MARK: - Dot Indicator

    private var pageIndicator: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            ForEach(pages.indices, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? AppTheme.Colors.accent : AppTheme.Colors.border)
                    .frame(width: index == currentPage ? 24 : 10, height: 10)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
    }

    // MARK: - CTA

    private var ctaButton: some View {
        Button {
            if isLastPage {
                HapticManager.success()
                onFinish()
            } else {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    currentPage += 1
                }
            }
        } label: {
            Text(isLastPage ? "Get Started" : "Continue")
                .font(.appSans(AppTheme.Typography.fontBody, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(AppTheme.Colors.heroGradient)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
    }

    private var skipButton: some View {
        Button("Skip") {
            onFinish()
        }
        .font(.appSans(AppTheme.Typography.fontLabel))
        .foregroundStyle(AppTheme.Colors.textMuted)
    }
}

// MARK: - Ambient Background

private struct AmbientShape: Identifiable {
    let id: Int
    /// Diameter, roughly 60–160pt.
    let size: CGFloat
    /// Position as a fraction of the container's width/height.
    let x: CGFloat
    let y: CGFloat
    /// Drift distance in points.
    let drift: CGFloat
    let duration: Double
    let delay: Double
    let opacity: Double
}

/// Scattered near the corners, clear of the centered icon/title/body copy.
private let ambientShapes: [AmbientShape] = [
    AmbientShape(id: 0, size: 110, x: 0.14, y: 0.11, drift: 14, duration: 7.5, delay: 0.0, opacity: 0.12),
    AmbientShape(id: 1, size: 150, x: 0.88, y: 0.19, drift: 18, duration: 9.0, delay: 1.4, opacity: 0.10),
    AmbientShape(id: 2, size: 70,  x: 0.12, y: 0.84, drift: 12, duration: 6.5, delay: 0.8, opacity: 0.15),
    AmbientShape(id: 3, size: 130, x: 0.90, y: 0.80, drift: 16, duration: 8.5, delay: 2.1, opacity: 0.09),
]

/// A handful of soft, slow-drifting blurred circles behind the onboarding
/// content — fills the empty corners without competing with the icon/text.
/// Rendered once (not per TabView page); its color cross-fades to the
/// current page's pastel whenever the page changes.
private struct AmbientBackground: View {
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ForEach(ambientShapes) { shape in
                DriftingCircle(shape: shape, color: color)
                    .position(x: geo.size.width * shape.x, y: geo.size.height * shape.y)
            }
        }
        .ignoresSafeArea()
    }
}

/// One ambient shape: a blurred circle that continuously drifts and pulses
/// in place via its own repeating easeInOut animation, offset from the
/// others by duration/delay so none of them move in sync.
private struct DriftingCircle: View {
    let shape: AmbientShape
    let color: Color

    @State private var animate = false

    var body: some View {
        Circle()
            .fill(color.opacity(shape.opacity))
            .frame(width: shape.size, height: shape.size)
            .scaleEffect(animate ? 1.05 : 0.95)
            .offset(x: animate ? shape.drift : -shape.drift, y: animate ? -shape.drift : shape.drift)
            .blur(radius: shape.size * 0.25)
            .animation(.easeInOut(duration: 0.6), value: color)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: shape.duration)
                        .repeatForever(autoreverses: true)
                        .delay(shape.delay)
                ) {
                    animate = true
                }
            }
    }
}

#Preview {
    OnboardingView(onFinish: {})
}
