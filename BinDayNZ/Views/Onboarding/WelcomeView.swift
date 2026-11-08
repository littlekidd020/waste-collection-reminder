import SwiftUI

/// The first screen: the household's bins standing on the linen, the name, three promises and
/// one way forward. The language menu sits above in glass so it can be changed before anything else.
struct WelcomeView: View {
    @Binding var language: AppLanguage
    let onContinue: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var binsIn = false
    @State private var wordsIn = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                languageMenu
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                hero
                    .padding(.top, 28)

                words
                    .padding(.horizontal, 24)
                    .padding(.top, 36)
                    .padding(.bottom, 24)
            }
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background { LinenGround() }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 16) {
                Button(action: onContinue) {
                    KerbPrimaryButtonLabel(title: L("Get Started"))
                }
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.capsule)
                .tint(Palette.accent)

                OnboardingPageIndicator(currentPage: 0)
            }
            .frame(maxWidth: 600)
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity)
            .background(alignment: .top) {
                // Lets scrolled text fade under the button rather than meeting a bar.
                LinearGradient(colors: [Palette.ground.opacity(0), Palette.ground.opacity(0.92)],
                               startPoint: .top, endPoint: .init(x: 0.5, y: 0.35))
                    .ignoresSafeArea(edges: .bottom)
                    .allowsHitTesting(false)
            }
            .opacity(wordsIn ? 1 : 0)
        }
        .onAppear(perform: enter)
    }

    // MARK: - Language

    private var languageMenu: some View {
        GlassEffectContainer {
            Menu {
                Picker(selection: $language) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                } label: {
                    EmptyView()
                }
                .pickerStyle(.inline)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "globe")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Palette.muted)
                    Text(language.displayName)
                        .kerbFont(15, .semibold, relativeTo: .subheadline)
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Palette.muted)
                }
                .foregroundStyle(Palette.ink)
                .padding(.horizontal, 16)
                .frame(minHeight: 44)
                .contentShape(.capsule)
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: .capsule)
            .accessibilityLabel(L("Language"))
            .accessibilityValue(language.displayName)
        }
    }

    // MARK: - Hero

    private var hero: some View {
        BinCluster(bins: [.recycling, .rubbish, .foodScraps], objectHeight: 230)
            .frame(maxWidth: .infinity)
            .frame(height: 230)
            .background(alignment: .bottom) {
                GroundBand(returns: true, peak: 0.6)
                    .frame(height: 170)
                    .offset(y: 58)
            }
            .opacity(binsIn ? 1 : 0)
            .offset(y: binsIn || reduceMotion ? 0 : 12)
            .accessibilityHidden(true)
    }

    // MARK: - Words

    private var words: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(verbatim: "Bin Day NZ")
                .kerbFont(34, .semibold, relativeTo: .largeTitle)
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .accessibilityAddTraits(.isHeader)
            Text(L("Your next bin day, made clear"))
                .kerbFont(17, relativeTo: .body)
                .foregroundStyle(Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)

            VStack(alignment: .leading, spacing: 14) {
                featureRow(icon: "trash", text: L("Know which bins go out tonight"))
                Hairline()
                featureRow(icon: "bell", text: L("Get a nudge the evening before"))
                Hairline()
                featureRow(icon: "lock.rectangle", text: L("See it on your lock screen"))
            }
            .padding(.top, 28)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(wordsIn ? 1 : 0)
        .offset(y: wordsIn || reduceMotion ? 0 : 8)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Palette.muted)
                .frame(width: 22)
                .accessibilityHidden(true)
            Text(text)
                .kerbFont(15, relativeTo: .subheadline)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Motion

    /// The bins settle up onto the floor, then the words fade in. Reduce Motion: fades only.
    private func enter() {
        guard !binsIn else { return }
        if reduceMotion {
            withAnimation(.easeOut(duration: 0.3)) { binsIn = true; wordsIn = true }
            return
        }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) { binsIn = true }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.85).delay(0.12)) { wordsIn = true }
    }
}
