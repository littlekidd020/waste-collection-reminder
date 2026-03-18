import SwiftUI

/// Welcome screen — first page of onboarding.
/// Shows app branding, bin icons, and a "Get Started" button.
struct WelcomeView: View {
    let onContinue: () -> Void

    @State private var animateIcons = false
    @State private var animateTitle = false
    @State private var showBounce = false

    var body: some View {
        ZStack {
            // Native system background
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // App icon area
                VStack(spacing: 20) {
                    // Animated bin icons
                    HStack(spacing: 24) {
                        binIcon("🔴", delay: 0.0)
                        binIcon("🟡", delay: 0.15)
                        binIcon("🟢", delay: 0.3)
                    }
                    .scaleEffect(animateIcons ? 1.0 : 0.5)
                    .opacity(animateIcons ? 1.0 : 0.0)

                    // App name
                    VStack(spacing: 8) {
                        Text("Bin Day")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        Text("NZ")
                            .font(.system(size: 42, weight: .light, design: .rounded))
                            .foregroundStyle(Color.green)
                    }
                    .opacity(animateTitle ? 1.0 : 0.0)
                    .offset(y: animateTitle ? 0 : 20)
                }

                // Tagline
                Text(String(localized: "Never miss a collection day"))
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .opacity(animateTitle ? 1.0 : 0.0)

                Spacer()

                // Features preview
                VStack(alignment: .leading, spacing: 16) {
                    featureRow(icon: "bell.fill", text: String(localized: "Smart reminders"))
                    featureRow(icon: "calendar", text: String(localized: "Calendar integration"))
                    featureRow(icon: "rectangle.on.rectangle", text: String(localized: "Home screen widget"))
                }
                .padding(.horizontal, 40)
                .opacity(animateTitle ? 1.0 : 0.0)

                Spacer()

                // Get Started button
                Button(action: onContinue) {
                    Text(String(localized: "Get Started"))
                        .font(.headline)
                        .foregroundStyle(.white) // Always white on green button
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.green)
                        )
                }
                .padding(.horizontal, 32)
                .opacity(animateTitle ? 1.0 : 0.0)

                // Page indicator (native look approximation)
                HStack(spacing: 8) {
                    Circle().fill(.secondary).frame(width: 8, height: 8)
                    Circle().fill(.quaternary).frame(width: 8, height: 8)
                    Circle().fill(.quaternary).frame(width: 8, height: 8)
                    Circle().fill(.quaternary).frame(width: 8, height: 8)
                }
                .padding(.bottom, 20)
            }
            .padding()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                animateIcons = true
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.5)) {
                animateTitle = true
            }
            
            // Re-trigger bounce effect periodically
            Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                showBounce.toggle()
            }
        }
    }

    private func binIcon(_ emoji: String, delay: Double) -> some View {
        Text(emoji)
            .font(.system(size: 48))
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
            .symbolEffect(.bounce, value: showBounce)
            // Note: symbolEffect on emoji might not animate like an SF Symbol, but will gracefully fallback.
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.green)
                .frame(width: 28)
                .symbolEffect(.bounce, value: showBounce)
            Text(text)
                .font(.body)
                .foregroundStyle(.primary)
        }
    }
}
