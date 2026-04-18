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
                VStack(spacing: 24) {
                    // Animated bin symbols
                    HStack(spacing: 28) {
                        binSymbol("trash.fill", color: .red, delay: 0.0)
                        binSymbol("trash.fill", color: .yellow, delay: 0.15)
                        binSymbol("trash.fill", color: .green, delay: 0.3)
                    }
                    .scaleEffect(animateIcons ? 1.0 : 0.5)
                    .opacity(animateIcons ? 1.0 : 0.0)

                    // App name
                    VStack(spacing: 8) {
                        Text("Bin Day")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        Text("NZ")
                            .font(.system(size: 44, weight: .light, design: .rounded))
                            .foregroundStyle(Color.green)
                    }
                    .opacity(animateTitle ? 1.0 : 0.0)
                    .offset(y: animateTitle ? 0 : 20)
                }

                // Tagline
                Text(L("Never miss a collection day"))
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.secondary)
                    .opacity(animateTitle ? 1.0 : 0.0)

                Spacer()

                // Features preview
                VStack(alignment: .leading, spacing: 18) {
                    featureRow(icon: "bell.fill", text: L("Smart reminders"))
                    featureRow(icon: "calendar", text: L("Calendar integration"))
                    featureRow(icon: "rectangle.on.rectangle", text: L("Home screen widget"))
                }
                .padding(.horizontal, 40)
                .opacity(animateTitle ? 1.0 : 0.0)

                Spacer()

                // Get Started button
                Button(action: onContinue) {
                    Text(L("Get Started"))
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.green)
                        )
                        .shadow(color: Color.green.opacity(0.3), radius: 10, y: 5)
                }
                .padding(.horizontal, 32)
                .opacity(animateTitle ? 1.0 : 0.0)

                // Page indicator
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

    private func binSymbol(_ name: String, color: Color, delay: Double) -> some View {
        Image(systemName: name)
            .font(.system(size: 48))
            .foregroundStyle(color)
            .shadow(color: color.opacity(0.2), radius: 8, y: 4)
            .symbolEffect(.bounce, value: showBounce)
            .rotationEffect(.degrees(showBounce ? 5 : -5))
            .animation(.interactiveSpring.delay(delay), value: showBounce)
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
