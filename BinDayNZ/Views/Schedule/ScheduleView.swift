import SwiftUI
import SwiftData

/// Schedule: the next fortnight as a street of kerbs, the month as a boxless grid of numerals, then
/// the next six collections set as type with their bins standing on each row's hairline.
struct ScheduleView: View {
    @Query private var profiles: [UserProfile]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var displayedMonth = Date()
    /// +1 when the last change moved forward, -1 backward: the grid pushes in from that side.
    @State private var monthStep = 1
    @State private var gridDrag: CGFloat = 0
    @State private var detail: ScheduleDay?
    @State private var showChangeAddress = false
    @State private var showCouncil = false
    @State private var shown = false
    @ScaledMetric(relativeTo: .footnote) private var leadColumn: CGFloat = 96

    private let engine = ScheduleEngine()
    private var calendar: Calendar { ScheduleEngine.collectionCalendar }
    private var zone: CollectionZone? { profiles.first.flatMap { DataService.shared.zone(for: $0) } }
    private var council: Council? { profiles.first.flatMap { DataService.shared.council(for: $0) } }
    private var monthStart: Date { calendar.dateInterval(of: .month, for: displayedMonth)?.start ?? displayedMonth }
    private var monthTitle: String { collectionDateLabel(monthStart, template: "MMMM yyyy") }

    var body: some View {
        TimelineView(.everyMinute) { context in
            ZStack {
                LinenGround()
                if let zone {
                    GeometryReader { geo in
                        content(zone, now: context.date, topInset: geo.safeAreaInsets.top)
                    }
                } else {
                    setupNeeded
                }
            }
        }
        .onAppear(perform: enter)
        .sheet(item: $detail) { day in
            DayDetailView(date: day.date, zone: zone)
                .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showChangeAddress) { ChangeAddressView() }
        .sheet(isPresented: $showCouncil) {
            SafariView(url: (council ?? CouncilDirectory.auckland).collectionDayURL).ignoresSafeArea()
        }
    }

    // MARK: - Layout

    private func content(_ zone: CollectionZone, now: Date, topInset: CGFloat) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                    .settle(shown, delay: 0, reduceMotion: reduceMotion)

                ScheduleStreet(zone: zone, now: now)
                    .settle(shown, delay: 0.04, reduceMotion: reduceMotion)

                month(zone, now: now)
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    .settle(shown, delay: 0.08, reduceMotion: reduceMotion)

                nextCollections(zone, now: now)
                    .padding(.horizontal, 24)
                    .padding(.top, 48)

                holidays(zone, now: now)
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    .settle(shown, delay: 0.4, reduceMotion: reduceMotion)

                footer
                    .padding(.horizontal, 24)
                    .padding(.top, 40)
                    .padding(.bottom, 24)
                    .settle(shown, delay: 0.44, reduceMotion: reduceMotion)
            }
            .frame(maxWidth: 600, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .overlay(alignment: .top) {
            // no bar on this screen: content fades out under the status bar instead of colliding with it
            let height = topInset + 18
            LinearGradient(stops: [.init(color: Palette.ground, location: 0),
                                   .init(color: Palette.ground.opacity(0.92), location: topInset / height),
                                   .init(color: Palette.ground.opacity(0), location: 1)],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: height)
                .ignoresSafeArea(edges: .top)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            // The street below always shows the coming fortnight; the month names itself above the grid.
            Text(L("The next fortnight"))
                .kerbLabel()
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)
            if let council {
                GlassEffectContainer {
                    GlassCircleButton(systemImage: "calendar.badge.clock", label: L("Check dates with %@", council.name)) {
                        showCouncil = true
                    }
                }
            }
        }
        .frame(minHeight: 44)
    }

    // MARK: - Month

    @ViewBuilder
    private func month(_ zone: CollectionZone, now: Date) -> some View {
        let collections = engine.collectionsForMonth(year: calendar.component(.year, from: monthStart),
                                                     month: calendar.component(.month, from: monthStart), zone: zone)
        let isCurrent = calendar.isDate(monthStart, equalTo: now, toGranularity: .month)
        VStack(alignment: .leading, spacing: 0) {
            Text(monthTitle)
                .kerbLabel()
                .monospacedDigit()
                .contentTransition(.numericText(countsDown: monthStep < 0))
                .accessibilityAddTraits(.isHeader)
                .padding(.bottom, 16)
            if dynamicTypeSize.isAccessibilitySize {
                monthList(collections)
            } else {
                weekdayInitials
                    .padding(.bottom, 12)
                ZStack {
                    ScheduleMonthGrid(month: monthStart, collections: collections, now: now) { date in
                        detail = ScheduleDay(date: date)
                    }
                    .id(monthStart)
                    .transition(reduceMotion ? .opacity : .push(from: monthStep >= 0 ? .trailing : .leading))
                }
                .offset(x: gridDrag)
                .clipped()
                .simultaneousGesture(monthSwipe)
            }
            if !isCurrent {
                Button {
                    monthStep = monthStart < now ? 1 : -1
                    withAnimation(monthAnimation) { displayedMonth = now }
                } label: {
                    Text(L("Show current month"))
                        .kerbFont(15, .semibold, relativeTo: .subheadline)
                        .foregroundStyle(Palette.accent)
                        .frame(minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
                .transition(.opacity)
            }
        }
    }

    /// The weekday letters double as the month's VoiceOver control: swipe up or down to change month.
    private var weekdayInitials: some View {
        HStack(spacing: 0) {
            ForEach(Array(ScheduleMonthGrid.weekdayInitials().enumerated()), id: \.offset) { _, letter in
                Text(letter)
                    .kerbLabel(12)
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(monthTitle)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: changeMonth(1)
            case .decrement: changeMonth(-1)
            @unknown default: break
            }
        }
    }

    private var monthSwipe: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                let t = value.translation
                guard abs(t.width) > abs(t.height) * 1.2 else { return }
                gridDrag = reduceMotion ? 0 : t.width * 0.3
            }
            .onEnded { value in
                let t = value.translation
                let horizontal = abs(t.width) > abs(t.height) * 1.2
                let reach = value.predictedEndTranslation.width
                if horizontal && abs(reach) > 90 {
                    changeMonth(reach < 0 ? 1 : -1)
                }
                withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { gridDrag = 0 }
            }
    }

    /// At accessibility text sizes the month reads as a list of collection days.
    private func monthList(_ collections: [Int: [BinType]]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            GlassEffectContainer(spacing: 12) {
                VStack(alignment: .leading, spacing: 12) {
                    monthButton(L("Previous month"), offset: -1)
                    monthButton(L("Next month"), offset: 1)
                }
            }
            .padding(.bottom, 16)
            Hairline()
            if collections.isEmpty {
                Text(L("No collections this month"))
                    .kerbFont(17, relativeTo: .body)
                    .foregroundStyle(Palette.muted)
                    .padding(.vertical, 16)
            } else {
                ForEach(collections.keys.sorted(), id: \.self) { day in
                    if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                        Button {
                            detail = ScheduleDay(date: date)
                        } label: {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(collectionDateLabel(date))
                                    .kerbFont(17, .semibold, relativeTo: .body)
                                    .foregroundStyle(Palette.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                                ForEach(collections[day, default: []]) { bin in
                                    CollectionBinRow(bin: bin)
                                        .kerbFont(17, relativeTo: .body)
                                }
                            }
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .accessibilityElement(children: .combine)
                        .accessibilityHint(L("Show collection details"))
                        Hairline()
                    }
                }
            }
        }
        .simultaneousGesture(monthSwipe)
    }

    private func monthButton(_ title: String, offset: Int) -> some View {
        Button { changeMonth(offset) } label: {
            Text(title)
                .kerbFont(17, .semibold, relativeTo: .body)
                .foregroundStyle(Palette.ink)
                .padding(.horizontal, 4)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.capsule)
        .controlSize(.large)
    }

    // MARK: - Next collections

    private func upcoming(_ zone: CollectionZone, now: Date) -> [ScheduleDay] {
        let collections = engine.upcomingCollections(for: zone, from: now, count: 60)
        let groups = Dictionary(grouping: collections, by: \.date)
        return groups.keys.sorted().prefix(6).map { ScheduleDay(date: $0, bins: groups[$0, default: []].map(\.binType)) }
    }

    private func nextCollections(_ zone: CollectionZone, now: Date) -> some View {
        let items = upcoming(zone, now: now)
        let fortnightlyRecycling = zone.schedules.contains { $0.binType == .recycling && $0.frequency == .fortnightly }
        return VStack(alignment: .leading, spacing: 0) {
            Text(L("Next collections"))
                .kerbLabel()
                .accessibilityAddTraits(.isHeader)
                .padding(.bottom, 4)
                .settle(shown, delay: 0.12, reduceMotion: reduceMotion)
            ForEach(Array(items.enumerated()), id: \.element.id) { i, item in
                row(item, previous: i > 0 ? items[i - 1].date : now, now: now, weekLine: fortnightlyRecycling)
                    .settle(shown, delay: 0.14 + 0.04 * Double(i), reduceMotion: reduceMotion)
            }
        }
    }

    private func row(_ item: ScheduleDay, previous: Date, now: Date, weekLine: Bool) -> some View {
        let today = calendar.startOfDay(for: now)
        let days = calendar.dateComponents([.day], from: today, to: item.date).day ?? 0
        let newMonth = !calendar.isDate(item.date, equalTo: previous, toGranularity: .month)
        let relative: String? = days <= 0 ? L("Today") : (days == 1 ? L("Tomorrow") : nil)
        // the first row of a new month names the month instead of the (usually repeating) weekday
        let label = relative ?? (newMonth ? collectionDateLabel(item.date, template: "MMMM") : collectionDateLabel(item.date, template: "EEEE"))
        let names = TodayCopy.list(item.bins)
        let week: String? = weekLine ? (item.bins.contains(.recycling) ? L("Recycling week") : L("No recycling")) : nil
        let propGap: CGFloat = -5
        let propsWidth = SchedulePropMetrics.width(of: item.bins, height: 32, spacing: propGap)
        let accessible = dynamicTypeSize.isAccessibilitySize

        let leading = VStack(alignment: .leading, spacing: 0) {
            Text(label)
                .kerbLabel(12)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(verbatim: "\(calendar.component(.day, from: item.date))")
                .kerbFont(34, .light, relativeTo: .largeTitle)
                .monospacedDigit()
                .foregroundStyle(Palette.ink)
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        }
        let text = VStack(alignment: .leading, spacing: 2) {
            Text(names)
                .kerbFont(17, relativeTo: .body)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            if let week {
                Text(week)
                    .kerbFont(15, relativeTo: .subheadline)
                    .foregroundStyle(Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }

        return ZStack(alignment: .bottomTrailing) {
            Group {
                if accessible {
                    VStack(alignment: .leading, spacing: 8) { leading; text }
                        .padding(.bottom, 44)
                } else {
                    HStack(alignment: .center, spacing: 0) {
                        leading.frame(width: min(leadColumn, 140), alignment: .leading)
                        text
                        Spacer(minLength: 0)
                    }
                    .padding(.trailing, propsWidth + 12)
                    .padding(.bottom, 8)
                }
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)

            HStack(alignment: .bottom, spacing: propGap) {
                ForEach(item.bins) { BinProp(bin: $0, objectHeight: 32) }
            }
            .accessibilityHidden(true)
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(Palette.line).frame(height: 1).offset(y: 0.5)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel((relative.map { $0 + ", " } ?? "") + collectionDateLabel(item.date))
        .accessibilityValue(week.map { names + ". " + $0 } ?? names)
    }

    // MARK: - Holidays and footer

    @ViewBuilder
    private func holidays(_ zone: CollectionZone, now: Date) -> some View {
        if let council {
            let suggestions = HolidayShiftService.suggestions(for: zone, council: council, now: now, dismissed: [])
            if !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(suggestions) { suggestion in
                        let date = collectionDateLabel(suggestion.holiday.date, template: "EEEE d MMMM")
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Image(systemName: "snowflake")
                                .kerbFont(13, relativeTo: .subheadline)
                                .accessibilityHidden(true)
                            Group {
                                if suggestion.policy.appliesAutomatically {
                                    Text(L("%@ is %@. Auckland Council: a collection on or after a public holiday runs one day later that week.",
                                           suggestion.holiday.name, date))
                                } else {
                                    Text(L("%@ is %@: collections that week may change.", suggestion.holiday.name, date))
                                }
                            }
                            .kerbFont(15, relativeTo: .subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                        }
                        .foregroundStyle(Palette.muted)
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L("Dates follow your saved schedule. Add any council-confirmed changes in Change schedule."))
                .kerbFont(13, relativeTo: .footnote)
                .foregroundStyle(Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 4)
            textButton(L("Change schedule")) { showChangeAddress = true }
            if let council {
                textButton(L("Check dates with %@", council.name)) { showCouncil = true }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func textButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .kerbFont(15, .semibold, relativeTo: .subheadline)
                .foregroundStyle(Palette.accent)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - No schedule

    private var setupNeeded: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L("Finish setup"))
                .kerbFont(34, .semibold, relativeTo: .largeTitle)
                .foregroundStyle(Palette.ink)
                .accessibilityAddTraits(.isHeader)
            Text(L("Confirm a collection schedule to see your next bin day."))
                .kerbFont(17, relativeTo: .body)
                .foregroundStyle(Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
            Button { showChangeAddress = true } label: {
                Text(L("Set Collection Schedule"))
                    .kerbFont(17, .semibold, relativeTo: .body)
                    .padding(.horizontal, 8)
            }
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .tint(Palette.accent)
        }
        .padding(24)
        .frame(maxWidth: 600, alignment: .leading)
    }

    // MARK: - Motion

    private var monthAnimation: Animation {
        reduceMotion ? .easeInOut(duration: 0.25) : .spring(response: 0.5, dampingFraction: 0.86)
    }

    private func changeMonth(_ offset: Int) {
        monthStep = offset
        withAnimation(monthAnimation) {
            displayedMonth = calendar.date(byAdding: .month, value: offset, to: monthStart) ?? displayedMonth
        }
    }

    private func enter() {
        guard !shown else { return }
        shown = true
    }
}

/// A collection date and its bins: a row in Next collections, or the day a sheet opens on.
struct ScheduleDay: Identifiable, Hashable {
    let date: Date
    var bins: [BinType] = []
    var id: Date { date }
}

private struct Settle: ViewModifier {
    let shown: Bool
    let delay: Double
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : 10)
            .animation(reduceMotion ? .easeOut(duration: 0.3).delay(delay)
                                    : .spring(response: 0.6, dampingFraction: 0.85).delay(delay),
                       value: shown)
    }
}

private extension View {
    /// Settles up into place on first appearance; a fade only with Reduce Motion.
    func settle(_ shown: Bool, delay: Double, reduceMotion: Bool) -> some View {
        modifier(Settle(shown: shown, delay: delay, reduceMotion: reduceMotion))
    }
}
