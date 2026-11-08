import SwiftUI

/// One bin's guide: when it is collected, the bin standing on the floor, what it is for, and what
/// goes in and stays out, then the council sources, footnotes and (for Auckland) the council video.
struct GuidePage: View {
    let bin: BinType
    let council: Council?
    /// The household's saved schedule for this bin, if it has one.
    let schedule: CollectionSchedule?
    let open: (URL) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var heroIn = false
    @State private var textIn = false

    private let heroHeight: CGFloat = 268
    private var isAuckland: Bool { council == CouncilDirectory.auckland }
    private var notes: [String] { bin.guideNotes(for: council) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                heading
                hero
                    .padding(.horizontal, -24)
                    .opacity(heroIn ? 1 : 0)
                    .offset(y: heroIn || reduceMotion ? 0 : 10)
                Group {
                    blurb
                    columns
                        .padding(.top, 32)
                    actions
                        .padding(.top, 32)
                    footnotes
                        .padding(.top, 24)
                    if let videoID = bin.youTubeVideoID(for: council), let videoURL = bin.videoURL {
                        Hairline()
                            .padding(.top, 32)
                        CouncilVideoSection(videoID: videoID, videoURL: videoURL, open: open)
                            .padding(.top, 24)
                    }
                }
                .opacity(textIn ? 1 : 0)
            }
            .padding(.horizontal, 24)
            .padding(.top, 68)
            .padding(.bottom, 120)
            .frame(maxWidth: 600, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .onAppear(perform: enter)
    }

    // MARK: - Heading

    private var eyebrow: String {
        if bin == .inorganic { return L("Booked collection") }
        guard let schedule else { return L("Not in your schedule") }
        let frequency = schedule.frequency == .weekly ? L("Weekly") : L("Fortnightly")
        return L("%@ · %@", frequency, collectionDateLabel(schedule.anchorDate, template: "EEEE"))
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(eyebrow).kerbLabel()
                .fixedSize(horizontal: false, vertical: true)
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            Text(bin.displayName)
                .kerbFont(40, relativeTo: .largeTitle)
                .foregroundStyle(Palette.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        }
        .opacity(textIn ? 1 : 0)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(bin.displayName)
        .accessibilityValue(eyebrow)
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Hero

    private var hero: some View {
        let band: CGFloat = dynamicTypeSize.isAccessibilitySize ? 180 : 120
        return ZStack(alignment: .bottom) {
            GroundBand(returns: true, peak: 0.62)
                .frame(height: band)
                .offset(y: band * 0.35)
            BinProp(bin: bin, objectHeight: heroHeight * closeUp)
        }
        .frame(maxWidth: .infinity)
        .frame(height: heroHeight + 8, alignment: .bottom)
        .padding(.top, 8)
        .padding(.bottom, 40)
        .accessibilityHidden(true)
    }


    /// The glass crate is under 40 % of a wheelie bin's height; on its own page the camera steps in
    /// so it still reads as the hero. Everything else keeps the shared scale, so the floor and the
    /// feet line stay put as the pages slide.
    private var closeUp: CGFloat { max(1, 0.55 / bin.propRelativeHeight) }

    // MARK: - Words

    private var blurb: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let first = notes.first {
                Text(first)
                    .kerbFont(17, relativeTo: .body)
                    .foregroundStyle(Palette.ink)
            }
            ForEach(notes.dropFirst(), id: \.self) { note in
                Text(note)
                    .kerbFont(15, relativeTo: .subheadline)
                    .foregroundStyle(Palette.muted)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var columns: some View {
        let yes = column(L("Yes"), bin.acceptedItems(for: council), color: Palette.ink)
        let no = column(L("No"), bin.rejectedItems(for: council), color: Palette.muted)
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 24) {
                yes
                Hairline()
                no
            }
        } else {
            HStack(alignment: .top, spacing: 20) {
                yes
                Rectangle()
                    .fill(Palette.line)
                    .frame(width: 0.5)
                    .accessibilityHidden(true)
                no
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func column(_ title: String, _ items: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).kerbLabel(12)
                .accessibilityAddTraits(.isHeader)
            ForEach(items, id: \.self) { item in
                Text(item)
                    .kerbFont(15, relativeTo: .subheadline)
                    .foregroundStyle(color)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
    }

    // MARK: - Actions and sources

    @ViewBuilder
    private var actions: some View {
        VStack(alignment: .leading, spacing: 4) {
            if bin == .inorganic && isAuckland {
                Button { open(Self.aucklandInorganicBooking) } label: {
                    Text(L("Book with Auckland Council"))
                        .kerbFont(17, .semibold, relativeTo: .body)
                        .padding(.horizontal, 8)
                        .frame(minHeight: 36)
                }
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.capsule)
                .tint(Palette.accent)
                .padding(.bottom, 8)
                textLink(L("Collection terms and limits"), Self.aucklandInorganicTerms)
            }
            textLink(L("Source: %@", (council ?? CouncilDirectory.auckland).name), bin.guideSourceURL(for: council))
            if bin == .foodScraps && isAuckland {
                textLink(L("Food scraps collection rules"), Self.aucklandFoodScrapsRules)
            }
        }
    }

    private func textLink(_ title: String, _ url: URL) -> some View {
        Button { open(url) } label: {
            Text(title)
                .kerbFont(15, .medium, relativeTo: .subheadline)
                .foregroundStyle(Palette.accent)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityAddTraits(.isLink)
    }

    private var footnotes: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(L("Before collection")).kerbLabel(12)
                    .accessibilityAddTraits(.isHeader)
                Text(L("Follow your property's collection time and placement instructions. Shared bins and apartments may have different arrangements."))
                Text(L("Keep lids closed and leave footpaths, driveways and access to the bins clear."))
            }
            .kerbFont(15, relativeTo: .subheadline)
            .foregroundStyle(Palette.muted)
            VStack(alignment: .leading, spacing: 6) {
                Text(L("Guide reviewed: %@", collectionDateLabel(BinType.guideReviewDate, template: "d MMMM y")))
                Text(L("These are common examples. Check the council source for unusual items or changes."))
            }
            .kerbFont(13, relativeTo: .footnote)
            .foregroundStyle(Palette.muted)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Motion

    private func enter() {
        guard !heroIn else { return }
        if reduceMotion {
            withAnimation(.easeOut(duration: 0.35)) { heroIn = true; textIn = true }
            return
        }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) { heroIn = true }
        withAnimation(.easeOut(duration: 0.45).delay(0.12)) { textIn = true }
    }

    // MARK: - Auckland links

    static let aucklandInorganicBooking = URL(string: "https://inorganiccollections.aucklandcouncil.govt.nz/Inorganic/")!
    static let aucklandInorganicTerms = URL(string: "https://new.aucklandcouncil.govt.nz/content/dam/ac/docs/rubbish-recycling/inorganiccollectiontermsandconditions.pdf")!
    static let aucklandFoodScrapsRules = URL(string: "https://www.aucklandcouncil.govt.nz/plans-projects-policies-reports-bylaws/bylaws/docssolidwastebylawoperationalcontrols/waste-management-minimisation-bylaw-collections-control.pdf")!
}
