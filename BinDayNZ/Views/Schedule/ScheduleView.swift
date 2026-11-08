import SwiftUI
import SwiftData

struct ScheduleView: View {
    @Query private var profiles: [UserProfile]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var displayedMonth = Date()
    @State private var selectedDate = Date()
    @State private var showsDayDetail = false
    @State private var showsList = false
    @State private var showChangeAddress = false

    private let engine = ScheduleEngine()
    private var calendar: Calendar { ScheduleEngine.collectionCalendar }
    private var currentZone: CollectionZone? {
        profiles.first.flatMap { DataService.shared.zone(for: $0) }
    }
    private var council: Council? { profiles.first.flatMap { DataService.shared.council(for: $0) } }
    private var year: Int { calendar.component(.year, from: displayedMonth) }
    private var month: Int { calendar.component(.month, from: displayedMonth) }
    private var monthCollections: [Int: [BinType]] {
        currentZone.map { engine.collectionsForMonth(year: year, month: month, zone: $0) } ?? [:]
    }

    var body: some View {
        NavigationStack {
            Group {
                if currentZone == nil {
                    ContentUnavailableView {
                        Label(L("Finish setup"), systemImage: "calendar.badge.exclamationmark")
                    } description: {
                        Text(L("Confirm a collection schedule to see your next bin day."))
                    } actions: {
                        Button(L("Set Collection Schedule")) { showChangeAddress = true }
                            .buttonStyle(.borderedProminent).tint(AppTheme.buttonFill)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            monthNavigation
                                .padding(.horizontal, 12)
                            if !dynamicTypeSize.isAccessibilitySize {
                                Picker(L("Schedule display"), selection: $showsList) {
                                    Text(L("Calendar")).tag(false)
                                    Text(L("List")).tag(true)
                                }
                                .pickerStyle(.segmented)
                                .padding(.horizontal, 12)
                            }
                            if showsList || dynamicTypeSize.isAccessibilitySize {
                                monthList
                                    .padding(.horizontal, 12)
                            } else {
                                monthGrid
                            }
                            VStack(alignment: .leading, spacing: 12) {
                                Text(L("Dates follow your saved schedule. Add any council-confirmed changes in Change schedule."))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                Button(L("Change schedule")) { showChangeAddress = true }
                                    .buttonStyle(.bordered)
                                    .controlSize(.large)
                                if let council {
                                    Link(L("Check dates with %@", council.name), destination: council.collectionDayURL)
                                        .frame(minHeight: 44, alignment: .leading)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                        }
                        .frame(maxWidth: 680)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(L("Schedule"))
            .sheet(isPresented: $showsDayDetail) {
                DayDetailView(date: selectedDate, zone: currentZone)
                    .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showChangeAddress) { ChangeAddressView() }
        }
    }

    private var monthNavigation: some View {
        let title = Text(collectionDateLabel(displayedMonth, template: "MMMM yyyy"))
            .font(.title3.bold())
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .accessibilityAddTraits(.isHeader)
        return VStack(spacing: 8) {
            if dynamicTypeSize.isAccessibilitySize { title }
            HStack(spacing: 8) {
                Button { changeMonth(-1) } label: {
                    Image(systemName: "chevron.left")
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(L("Previous month"))
                if dynamicTypeSize.isAccessibilitySize { Spacer() }
                else { title }
                Button { changeMonth(1) } label: {
                    Image(systemName: "chevron.right")
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(L("Next month"))
            }
            Button(L("Show current month")) {
                displayedMonth = Date()
                selectedDate = Date()
            }
            .frame(minHeight: 44)
        }
    }

    private var monthGrid: some View {
        let firstDate = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
        let days = calendar.range(of: .day, in: .month, for: firstDate)!.count
        let offset = (calendar.component(.weekday, from: firstDate) + 5) % 7
        let cells = ((offset + days + 6) / 7) * 7
        let collections = monthCollections
        var localizedCalendar = calendar
        localizedCalendar.locale = LanguageManager.shared.locale
        let symbols = localizedCalendar.shortStandaloneWeekdaySymbols
        let mondayFirst = Array(symbols.dropFirst()) + [symbols[0]]

        return VStack(spacing: 6) {
            HStack(spacing: 0) {
                ForEach(Array(mondayFirst.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .accessibilityHidden(true)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 44), spacing: 0), count: 7), spacing: 6) {
                ForEach(0..<cells, id: \.self) { cell in
                    let day = cell - offset + 1
                    if (1...days).contains(day) {
                        dayCell(day, date: calendar.date(byAdding: .day, value: day - 1, to: firstDate)!, bins: collections[day, default: []])
                    } else {
                        Color.clear.frame(height: 64)
                            .accessibilityHidden(true)
                    }
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                ForEach(BinType.allCases.filter { $0 != .inorganic }) { bin in
                    CollectionBinRow(bin: bin)
                        .font(.subheadline)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
        }
    }

    private func dayCell(_ day: Int, date: Date, bins: [BinType]) -> some View {
        let selected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)

        return Button {
            selectedDate = date
            showsDayDetail = true
        } label: {
            VStack(spacing: 8) {
                Text(day, format: .number)
                    .font(.body.weight(isToday ? .bold : .regular))
                HStack(spacing: 0) {
                    ForEach(bins) { bin in
                        Image(systemName: bin.systemImage)
                            .symbolVariant(.none)
                            .font(.system(size: 14, weight: .medium))
                            .frame(width: 14)
                    }
                }
                .frame(height: 16)
            }
            .foregroundStyle(.primary)
            .frame(minWidth: 44, maxWidth: .infinity, minHeight: 64)
            .background(selected ? AppTheme.accent.opacity(0.14) : Color.clear, in: RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(selected ? AppTheme.accent : Color.clear, lineWidth: 2)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(collectionDateLabel(date) + (isToday ? ", " + L("Today") : ""))
        .accessibilityValue(bins.isEmpty ? L("No collection") : bins.map(\.displayName).joined(separator: ", "))
        .accessibilityHint(L("Show collection details"))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var monthList: some View {
        let collections = monthCollections
        return LazyVStack(alignment: .leading, spacing: 12) {
            if collections.isEmpty {
                ContentUnavailableView(L("No collections this month"), systemImage: "calendar")
            } else {
                ForEach(collections.keys.sorted(), id: \.self) { day in
                    let date = calendar.date(from: DateComponents(year: year, month: month, day: day))!
                    Button {
                        selectedDate = date
                        showsDayDetail = true
                    } label: {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(collectionDateLabel(date))
                                .font(.headline)
                            ForEach(collections[day, default: []]) { bin in
                                CollectionBinRow(bin: bin)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                    .accessibilityHint(L("Show collection details"))
                    .accessibilityAddTraits(calendar.isDate(date, inSameDayAs: selectedDate) ? .isSelected : [])
                }
            }
        }
    }

    private func changeMonth(_ offset: Int) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.15)) {
            displayedMonth = calendar.date(byAdding: .month, value: offset, to: displayedMonth) ?? displayedMonth
        }
    }
}

struct DayDetailView: View {
    let date: Date
    let zone: CollectionZone?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(collectionDateLabel(date))
                        .font(.title2.bold())
                    let bins = zone.map { ScheduleEngine().binsCollectedOn(date: date, zone: $0) } ?? []
                    if bins.isEmpty {
                        Label(L("No collection on this day"), systemImage: "calendar")
                    } else {
                        ForEach(bins) { bin in
                            CollectionBinRow(bin: bin)
                                .font(.title3.weight(.semibold))
                        }
                    }
                }
                .frame(maxWidth: 680, alignment: .leading)
                .padding(24)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle(L("Collection details"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("Done")) { dismiss() }
                }
            }
        }
    }
}

/// Dates in the collection views always describe the property's New Zealand day.
/// Formatters are cached per template and language; the month grid asks for dozens per render.
func collectionDateLabel(_ date: Date, template: String = "EEEE d MMMM") -> String {
    CollectionDateFormatters.shared.formatter(template: template, languageCode: LanguageManager.shared.currentCode).string(from: date)
}

final class CollectionDateFormatters {
    static let shared = CollectionDateFormatters()
    private let lock = NSLock()
    private var formatters: [String: DateFormatter] = [:]

    func formatter(template: String, languageCode: String) -> DateFormatter {
        let key = languageCode + "|" + template
        lock.lock(); defer { lock.unlock() }
        if let formatter = formatters[key] { return formatter }
        let formatter = DateFormatter()
        formatter.calendar = ScheduleEngine.collectionCalendar
        formatter.timeZone = ScheduleEngine.collectionCalendar.timeZone
        formatter.locale = Locale.app(languageCode)
        formatter.setLocalizedDateFormatFromTemplate(template)
        formatters[key] = formatter
        return formatter
    }
}
