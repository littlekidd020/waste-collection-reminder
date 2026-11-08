import SwiftUI
import SwiftData
import WidgetKit
import CoreLocation
import UIKit

/// Today: the household's next bins stand on the linen floor and the words say whether tonight is
/// bin night. Swipe the bins right and they roll to the kerb, which silences that collection's
/// evening and morning reminders. Settings, the council and schedule changes hang off the chrome.
struct TodayView: View {
    var openSettings: () -> Void = {}

    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.openURL) private var openURL
    @State private var coordinator = ScheduleCoordinator.shared
    @State private var showChangeAddress = false
    @State private var showHowItWorks = false
    @State private var showCouncil = false
    @State private var widgetInstalled: Bool?
    @AppStorage("widgetNudgeDismissed") private var widgetNudgeDismissed = false
    @AppStorage("dismissedHolidayIDs") private var dismissedHolidayIDs = ""

    // Motion
    @State private var binsIn = false
    @State private var captionsIn = false
    @State private var verdictIn = false
    @State private var dragX: CGFloat = 0
    @State private var tilt: Double = -5
    @State private var stageFrame: CGRect = .zero
    @State private var measured: [String: CGFloat] = [:]
    @State private var kerbHaptic = false

    private let engine = ScheduleEngine()
    private let kerbShift: CGFloat = 54
    private var profile: UserProfile? { profiles.first }
    private var zone: CollectionZone? { profile.flatMap { DataService.shared.zone(for: $0) } }
    private var council: Council? { profile.flatMap { DataService.shared.council(for: $0) } }

    var body: some View {
        TimelineView(.everyMinute) { context in
            GeometryReader { geo in
                ZStack(alignment: .top) {
                    if let profile, let zone, let model = TodayModel(zone: zone, profile: profile, now: context.date, engine: engine) {
                        if usesScrollLayout(geo) {
                            scrolling(model, profile: profile, zone: zone, geo: geo)
                        } else {
                            standing(model, profile: profile, zone: zone, geo: geo)
                        }
                    } else {
                        setupNeeded
                    }
                }
                .coordinateSpace(name: "today")
            }
        }
        .sensoryFeedback(.success, trigger: kerbHaptic)
        .task { await checkWidgets() }
        .onChange(of: coordinator.isUpdating) { _, _ in Task { await checkWidgets() } }
        .onAppear(perform: enter)
        .sheet(isPresented: $showChangeAddress) { ChangeAddressView() }
        .sheet(isPresented: $showCouncil) { SafariView(url: (council ?? CouncilDirectory.auckland).collectionDayURL).ignoresSafeArea() }
        .sheet(isPresented: $showHowItWorks) {
            NavigationStack {
                HowItWorksView(council: council)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button(L("Done")) { showHowItWorks = false }
                        }
                    }
            }
        }
    }

    /// The height everything but the bins needs, measured on the last layout (zero until then).
    private var fixedHeight: CGFloat { measured.values.reduce(0, +) }

    /// Accessibility text sizes, short screens and text that leaves the bins under 150 pt scroll;
    /// everything else stands in one frame.
    private func usesScrollLayout(_ geo: GeometryProxy) -> Bool {
        if dynamicTypeSize.isAccessibilitySize || geo.size.height < 640 { return true }
        return fixedHeight > 0 && stageHeight(geo) < 150
    }

    // MARK: - Standing layout

    private func standing(_ m: TodayModel, profile: UserProfile, zone: CollectionZone, geo: GeometryProxy) -> some View {
        ZStack(alignment: .top) {
            ground(feetY: stageFrame.maxY)
            VStack(alignment: .leading, spacing: 0) {
                topBar(profile)
                    .padding(.top, 8)
                    .measureHeight("top", into: $measured)
                words(m)
                    .padding(.top, 28)
                    .measureHeight("words", into: $measured)
                    .padding(.top, wordsAir(geo))
                Spacer(minLength: 8)
                stage(m, profile: profile, width: min(geo.size.width, 600) - 48,
                      fixedHeight: fixedHeight > 0 ? max(150, stageHeight(geo) - wordsAir(geo)) : nil,
                      cap: geo.size.width >= 700 ? 420 : 300)
                    .layoutPriority(fixedHeight > 0 ? 0 : 1)
                captions(m)
                    .padding(.top, 22)
                    .measureHeight("captions", into: $measured)
                Group {
                    if let following = m.following {
                        Text(following)
                            .kerbFont(15, relativeTo: .subheadline)
                            .foregroundStyle(Palette.muted)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .fixedSize(horizontal: false, vertical: true)
                            .opacity(captionsIn ? 1 : 0)
                            .padding(.top, 14)
                    }
                }
                .measureHeight("following", into: $measured)
                Spacer(minLength: 8)
                VStack(spacing: 0) { attention(m, profile: profile, zone: zone) }
                    .measureHeight("attention", into: $measured)
                footer(m, profile: profile)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    .measureHeight("footer", into: $measured)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: 600)
            // On an iPad the block keeps a phone's proportions and floats in the middle of the screen.
            .frame(maxHeight: Self.standingBlockHeight(geo))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    /// Tall screens cap the standing block so the words stay near the bins.
    private static func standingBlockHeight(_ geo: GeometryProxy) -> CGFloat { min(geo.size.height, 900) }

    /// When the bins have more room than they can use (they stop growing at the cap), part of the
    /// spare height moves above the words, so the gap between words and bins does not carry it all.
    /// Measured heights exclude this padding, so it cannot feed back into itself.
    private func wordsAir(_ geo: GeometryProxy) -> CGFloat {
        guard fixedHeight > 0 else { return 0 }
        let cap: CGFloat = geo.size.width >= 700 ? 420 : 300
        let spare = stageHeight(geo) - cap / 0.94
        return max(0, min(72, spare * 0.5))
    }

    /// Room left for the bins in the standing layout: the block minus the measured text and chrome.
    private func stageHeight(_ geo: GeometryProxy) -> CGFloat { Self.standingBlockHeight(geo) - fixedHeight - 16 }

    // MARK: - Scrolling layout (accessibility sizes, short screens)

    private func scrolling(_ m: TodayModel, profile: UserProfile, zone: CollectionZone, geo: GeometryProxy) -> some View {
        ZStack {
            LinenGround()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    topBar(profile)
                        .padding(.top, 8)
                        .measureHeight("top", into: $measured)
                    words(m)
                        .padding(.top, 8)
                        .measureHeight("words", into: $measured)
                    stage(m, profile: profile, width: min(geo.size.width, 600) - 48, fixedHeight: 190, cap: 190)
                        .background(alignment: .bottom) {
                            GroundBand(returns: true, peak: 0.6)
                                .frame(height: 150)
                                .padding(.horizontal, -geo.size.width)
                                .offset(y: 50)
                        }
                        .padding(.top, 12)
                    captions(m)
                        .padding(.top, 2)
                        .measureHeight("captions", into: $measured)
                    Group {
                        if let following = m.following {
                            Text(following)
                                .kerbFont(15, relativeTo: .subheadline)
                                .foregroundStyle(Palette.muted)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 14)
                        }
                    }
                    .measureHeight("following", into: $measured)
                    VStack(spacing: 0) { attention(m, profile: profile, zone: zone) }
                        .measureHeight("attention", into: $measured)
                    footer(m, profile: profile)
                        .padding(.top, 16)
                        .padding(.bottom, 24)
                        .measureHeight("footer", into: $measured)
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: 600, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: - Ground

    /// Linen, easing into the deeper surface linen from just above the bins' feet.
    private func ground(feetY: CGFloat) -> some View {
        GeometryReader { g in
            let origin = g.frame(in: .named("today")).minY
            ZStack(alignment: .top) {
                Palette.ground
                VStack(spacing: 0) {
                    Color.clear.frame(height: max(0, feetY - origin - 59))
                    GroundBand().frame(height: 120)
                    Palette.surface
                }
                Grain()
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - Chrome

    private func topBar(_ profile: UserProfile) -> some View {
        let place = TodayCopy.shortAddress(profile.address) ?? council?.name ?? L("Your schedule")
        return GlassEffectContainer(spacing: 12) {
            ZStack {
                Menu {
                    Button { showChangeAddress = true } label: {
                        Label(L("Change schedule"), systemImage: "calendar.badge.clock")
                    }
                    if let council {
                        Button { showCouncil = true } label: {
                            Label(L("Check dates with %@", council.name), systemImage: "safari")
                        }
                    }
                    Button { showHowItWorks = true } label: {
                        Label(L("How Bin Day works"), systemImage: "questionmark.circle")
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(place)
                            .kerbFont(15, .semibold, relativeTo: .subheadline)
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Palette.muted)
                    }
                    .foregroundStyle(Palette.ink)
                    .padding(.horizontal, 18)
                    .frame(minHeight: 44)
                    .contentShape(.capsule)
                }
                .menuStyle(.button)
                .buttonStyle(.plain)
                .glassEffect(.regular.interactive(), in: .capsule)
                .accessibilityLabel(L("Schedule options"))
                .accessibilityValue(place)

                HStack {
                    Spacer()
                    GlassCircleButton(systemImage: "gearshape", label: L("Settings"), action: openSettings)
                }
            }
        }
    }

    // MARK: - Words

    private func words(_ m: TodayModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(m.eyebrow)
                .kerbLabel()
                .monospacedDigit()
            VStack(alignment: .leading, spacing: 8) {
                Text(m.verdict)
                    .kerbFont(44, .semibold, relativeTo: .largeTitle)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                    .foregroundStyle(Palette.ink)
                    .minimumScaleFactor(0.6)
                    .lineLimit(2)
                    .contentTransition(.interpolate)
                Text(m.sentence)
                    .kerbFont(17, relativeTo: .body)
                    .foregroundStyle(Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(verdictIn ? 1 : 0)
        .offset(y: verdictIn ? 0 : 12)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Stage

    private var xShift: CGFloat { dragX }

    private func stage(_ m: TodayModel, profile: UserProfile, width: CGFloat, fixedHeight: CGFloat?, cap: CGFloat) -> some View {
        let relativeWidth = max(0.6, BinCluster.relativeWidth(of: m.nextBins))
        let byWidth = width / relativeWidth
        let room = fixedHeight ?? stageFrame.height
        let objectHeight = max(100, min(room * 0.94, cap, byWidth))
        let shift = (m.atKerb ? min(kerbShift, max(0, (width - objectHeight * relativeWidth) / 2)) : 0) + dragX
        return ZStack(alignment: .bottom) {
            Ellipse()
                .fill(Palette.shadow.opacity(0.07))
                .frame(width: objectHeight * relativeWidth * 0.95, height: objectHeight * 0.11)
                .blur(radius: 14)
                .offset(x: shift + 6, y: objectHeight * 0.02)
            BinCluster(bins: m.nextBins, objectHeight: objectHeight)
                .rotationEffect(.degrees(binsIn ? tilt : -5), anchor: .bottom)
                .offset(x: shift + (binsIn ? 0 : width))
                .opacity(reduceMotion && !binsIn ? 0 : 1)
        }
        .frame(maxWidth: .infinity, maxHeight: fixedHeight ?? .infinity, alignment: .bottom)
        .frame(height: fixedHeight)
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named("today")) } action: { stageFrame = $0 }
        .contentShape(Rectangle())
        .gesture(rollGesture(m, profile: profile), including: m.phase.allowsKerb ? .all : .subviews)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L("%@ bins", TodayCopy.list(m.displayBins)))
        .accessibilityHint(m.phase.allowsKerb && !m.atKerb ? L("Swipe right when they are out") : "")
        .accessibilityAction(named: m.atKerb ? L("Bring the bins back") : L("Mark bins as out")) {
            if m.phase.allowsKerb { roll(toKerb: !m.atKerb, m, profile: profile) }
        }
    }

    private func captions(_ m: TodayModel) -> some View {
        FlowLayout(spacing: 24, rowSpacing: 8) {
            ForEach(m.displayBins) { BinCaption(bin: $0) }
        }
        .frame(maxWidth: .infinity)
        .opacity(captionsIn ? 1 : 0)
        .offset(y: captionsIn ? 0 : 6)
    }

    // MARK: - Attention and footer

    @ViewBuilder
    private func attention(_ m: TodayModel, profile: UserProfile, zone: CollectionZone) -> some View {
        if let council, let suggestion = HolidayShiftService.suggestions(for: zone, council: council, now: m.now, dismissed: dismissedHolidays).first {
            HolidayShiftCard(suggestion: suggestion, council: council) {
                applyHoliday(suggestion, zone: zone, profile: profile)
            } onDismiss: {
                dismissHoliday(suggestion.holiday.id)
            }
            .padding(.top, 16)
        } else if shouldNudgeWidget(profile: profile, now: m.now) {
            WidgetNudgePanel { widgetNudgeDismissed = true }
                .padding(.top, 16)
        }
    }

    private enum ReminderState { case checking, off, denied, paused(Date), scheduled, stale }

    private func reminderState(_ profile: UserProfile, now: Date) -> ReminderState {
        if coordinator.isUpdating || !coordinator.hasCheckedAuthorization { return .checking }
        if !profile.reminderPreferences.isEnabled { return .off }
        if !coordinator.notificationsAuthorized { return .denied }
        let today = ScheduleEngine.collectionCalendar.startOfDay(for: now)
        if let pausedUntil = profile.remindersPausedUntil, pausedUntil >= today { return .paused(pausedUntil) }
        if let through = profile.remindersScheduledThrough, through >= today { return .scheduled }
        return .stale
    }

    @ViewBuilder
    private func footer(_ m: TodayModel, profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let message = profile.integrationMessage, !message.isEmpty {
                Label(message, systemImage: "exclamationmark.triangle")
                    .kerbFont(14, relativeTo: .footnote)
                    .foregroundStyle(Palette.attention)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if m.atKerb {
                Button {
                    roll(toKerb: false, m, profile: profile)
                } label: {
                    Text(L("Undo"))
                        .kerbFont(17, .semibold, relativeTo: .body)
                        .foregroundStyle(Palette.ink)
                        .padding(.horizontal, 8)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                .accessibilityHint(L("Bring the bins back"))
            } else {
                switch reminderState(profile, now: m.now) {
                case .checking:
                    HStack(spacing: 10) {
                        ProgressView().controlSize(.small)
                        Text(L("Checking reminders")).kerbFont(15, relativeTo: .subheadline)
                    }
                    .foregroundStyle(Palette.muted)
                    .frame(minHeight: 44)
                case .off:
                    callToAction(L("Turn on reminders"), action: openSettings)
                case .denied:
                    callToAction(L("Allow notifications")) {
                        if let url = URL(string: UIApplication.openNotificationSettingsURLString) { openURL(url) }
                    }
                case .stale:
                    callToAction(L("Refresh reminders")) {
                        Task { await coordinator.refresh(profile: profile, context: modelContext) }
                    }
                case .paused(let until):
                    statusLine(symbol: "bell.slash", text: L("Reminders paused until %@", collectionDateLabel(until, template: "d MMMM")))
                case .scheduled:
                    statusLine(symbol: "bell", text: L("Reminders on · %@", TodayCopy.reminderTimes(profile.reminderPreferences)))
                }
            }
        }
        .opacity(verdictIn ? 1 : 0)
    }

    private func callToAction(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .kerbFont(17, .semibold, relativeTo: .body)
                .foregroundStyle(Palette.onAccent)
                .padding(.horizontal, 8)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.capsule)
        .controlSize(.large)
        .tint(Palette.accent)
    }

    private func statusLine(symbol: String, text: String) -> some View {
        Button(action: openSettings) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .accessibilityHidden(true)
                Text(text)
                    .kerbFont(15, relativeTo: .subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(Palette.muted)
            .frame(minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint(L("Opens Settings"))
    }

    private var setupNeeded: some View {
        ZStack {
            LinenGround()
            VStack(alignment: .leading, spacing: 16) {
                Text(L("Finish setup"))
                    .kerbFont(34, .semibold, relativeTo: .largeTitle)
                    .foregroundStyle(Palette.ink)
                Text(L("Confirm a collection schedule to see your next bin day."))
                    .kerbFont(17, relativeTo: .body)
                    .foregroundStyle(Palette.muted)
                callToAction(L("Set Collection Schedule")) { showChangeAddress = true }
            }
            .padding(24)
            .frame(maxWidth: 600, alignment: .leading)
        }
    }

    // MARK: - Motion

    private func enter() {
        guard !binsIn else { return }
        if reduceMotion {
            tilt = 0
            withAnimation(.easeOut(duration: 0.35)) { binsIn = true; captionsIn = true; verdictIn = true }
            return
        }
        // the bins roll in from the right, leaning on their wheels, then stand upright
        withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) { binsIn = true }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.7).delay(0.38)) { tilt = 0 }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.85).delay(0.08)) { verdictIn = true }
        withAnimation(.easeOut(duration: 0.45).delay(0.78)) { captionsIn = true }
    }

    private func rollGesture(_ m: TodayModel, profile: UserProfile) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                let dx = value.translation.width
                if m.atKerb {
                    dragX = min(0, dx) * 0.5
                    tilt = max(-4, Double(dragX) / 12)
                } else {
                    dragX = max(0, dx) * 0.5
                    tilt = min(4, Double(dragX) / 12)
                }
            }
            .onEnded { value in
                let dx = value.predictedEndTranslation.width
                if !m.atKerb && dx > 120 {
                    roll(toKerb: true, m, profile: profile)
                } else if m.atKerb && dx < -120 {
                    roll(toKerb: false, m, profile: profile)
                } else {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { dragX = 0; tilt = 0 }
                }
            }
    }

    /// Rolls the bins to the kerb (or back) and records it, so the reminder batch skips this collection.
    private func roll(toKerb: Bool, _ m: TodayModel, profile: UserProfile) {
        let value: Date? = toKerb ? m.nextDate : nil
        if reduceMotion {
            withAnimation(.easeInOut(duration: 0.3)) { profile.binsOutForCollectionOn = value; dragX = 0; tilt = 0 }
        } else {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                profile.binsOutForCollectionOn = value; dragX = 0; tilt = toKerb ? 4 : -4
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.32)) { tilt = 0 }
        }
        kerbHaptic.toggle()
        do { try modelContext.save() } catch { modelContext.rollback() }
        Task { await coordinator.refresh(profile: profile, context: modelContext) }
    }
}

// MARK: - Model

/// What Today shows, computed once per minute from the saved schedule.
struct TodayModel {
    let now: Date
    let nextDate: Date
    let nextBins: [BinType]
    let followingDate: Date?
    let followingBins: [BinType]
    let phase: TodayCopy.Phase
    let atKerb: Bool

    init?(zone: CollectionZone, profile: UserProfile, now: Date, engine: ScheduleEngine) {
        let collections = engine.upcomingCollections(for: zone, from: now, count: 24)
        let groups = Dictionary(grouping: collections, by: \.date)
        let dates = groups.keys.sorted()
        guard let next = dates.first else { return nil }
        self.now = now
        nextDate = next
        nextBins = groups[next, default: []].map(\.binType)
        followingDate = dates.dropFirst().first
        followingBins = followingDate.map { groups[$0, default: []].map(\.binType) } ?? []
        phase = TodayCopy.phase(now: now, next: next)
        atKerb = phase.allowsKerb && profile.binsOutForCollectionOn.map { ScheduleEngine.collectionCalendar.isDate($0, inSameDayAs: next) } == true
    }

    /// The next bins in the order they stand on screen.
    var displayBins: [BinType] { BinCluster.displayOrder(nextBins) }
    var eyebrow: String { TodayCopy.eyebrow(phase: phase, date: nextDate) }
    var verdict: String { TodayCopy.verdict(phase: phase, atKerb: atKerb) }
    var sentence: String { TodayCopy.sentence(phase: phase, atKerb: atKerb, bins: displayBins, date: nextDate) }
    var following: String? {
        guard let followingDate else { return nil }
        return TodayCopy.following(date: followingDate, bins: followingBins)
    }
}

// MARK: - Helpers

private extension View {
    /// Records this view's laid-out height under a key, so Today can size the bins to what is left.
    func measureHeight(_ key: String, into store: Binding<[String: CGFloat]>) -> some View {
        onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
            if store.wrappedValue[key] != height { store.wrappedValue[key] = height }
        }
    }
}

extension TodayView {
    fileprivate var dismissedHolidays: Set<String> {
        Set(dismissedHolidayIDs.split(separator: ",").map(String.init))
    }

    fileprivate func dismissHoliday(_ id: String) {
        dismissedHolidayIDs = (dismissedHolidays.union([id])).sorted().joined(separator: ",")
    }

    fileprivate func applyHoliday(_ suggestion: HolidaySuggestion, zone: CollectionZone, profile: UserProfile) {
        guard let updated = HolidayShiftService.applying(suggestion, to: zone) else { return }
        let coordinate = profile.latitude.flatMap { lat in profile.longitude.map { CLLocationCoordinate2D(latitude: lat, longitude: $0) } }
        Task { @MainActor in
            try? await ScheduleCoordinator.shared.save(zone: updated, council: nil, address: profile.address, coordinate: coordinate, profile: profile, context: modelContext)
        }
    }

    /// Two weeks after confirming a schedule, suggest the widget once if none is installed.
    fileprivate func shouldNudgeWidget(profile: UserProfile, now: Date) -> Bool {
        guard widgetInstalled == false, !widgetNudgeDismissed, let confirmed = profile.scheduleConfirmedAt else { return false }
        return now.timeIntervalSince(confirmed) > 14 * 86400
    }

    fileprivate func checkWidgets() async {
        let installed: Bool = await withCheckedContinuation { continuation in
            WidgetCenter.shared.getCurrentConfigurations { result in
                continuation.resume(returning: !((try? result.get()) ?? []).isEmpty)
            }
        }
        widgetInstalled = installed
    }
}
