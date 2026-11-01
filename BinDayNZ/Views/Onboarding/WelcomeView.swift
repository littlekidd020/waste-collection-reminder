import SwiftUI

struct WelcomeView: View {
    @Binding var language: AppLanguage
    let onContinue: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var contentVisible = false

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                HStack {
                    Spacer()
                    Picker(selection: $language) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.displayName).tag(language)
                        }
                    } label: {
                        Label(language.displayName, systemImage: "globe")
                    }
                    .pickerStyle(.menu)
                    .accessibilityLabel(L("Language"))
                }

                VStack(spacing: 24) {
                    HStack(spacing: 28) {
                        binSymbol(color: .red)
                        binSymbol(color: .yellow)
                        binSymbol(color: .green)
                    }
                    .scaleEffect(contentVisible || reduceMotion ? 1 : 0.92)
                    .opacity(contentVisible || reduceMotion ? 1 : 0)
                    .accessibilityHidden(true)

                    VStack(spacing: 4) {
                        Text("Bin Day")
                            .font(.largeTitle.bold())
                        Text("NZ")
                            .font(.largeTitle.weight(.light))
                            .foregroundStyle(.green)
                    }
                    .accessibilityElement(children: .combine)
                }

                Text(L("Your next bin day, made clear"))
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 18) {
                    featureRow(icon: "trash", text: L("Know which bins go out tonight"))
                    featureRow(icon: "bell", text: L("Get a nudge the evening before"))
                    featureRow(icon: "lock.rectangle", text: L("See it on your lock screen"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
            }
            .padding(24)
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
            .opacity(contentVisible || reduceMotion ? 1 : 0)
            .offset(y: contentVisible || reduceMotion ? 0 : 12)
        }
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 14) {
                Button(action: onContinue) {
                    Text(L("Get Started"))
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.buttonFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(ScaleButtonStyle())

                OnboardingPageIndicator(currentPage: 0)
            }
            .frame(maxWidth: 600)
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(.bar)
        }
        .onAppear {
            if reduceMotion {
                contentVisible = true
            } else {
                withAnimation(.spring(response: 0.4, dampingFraction: 1)) {
                    contentVisible = true
                }
            }
        }
    }

    private func binSymbol(color: Color) -> some View {
        Image(systemName: "trash")
            .font(.largeTitle)
            .foregroundStyle(color)
            .shadow(color: color.opacity(0.2), radius: 8, y: 4)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.green)
                .frame(width: 28)
                .accessibilityHidden(true)
            Text(text)
                .font(.body)
        }
        .accessibilityElement(children: .combine)
    }
}
