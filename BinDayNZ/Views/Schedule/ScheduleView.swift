import SwiftUI
import SwiftData

/// Monthly calendar view showing colour-coded collection dots per day.
struct ScheduleView: View {
    @Query private var profiles: [UserProfile]
    @State private var displayedMonth = Date()
    @State private var selectedDate: Date?

    private let engine = ScheduleEngine()
    private let dataService = DataService.shared
    private let calendar = Calendar.current

    private var profile: UserProfile? { profiles.first }

    private var currentZone: CollectionZone? {
        guard let profile = profile,
              let councilId = profile.councilId,
              let zoneId = profile.zoneId else { return nil }
        return dataService.zone(withId: zoneId, in: councilId)
    }

    private var year: Int { calendar.component(.year, from: displayedMonth) }
    private var month: Int { calendar.component(.month, from: displayedMonth) }

    private var monthCollections: [Int: [BinType]] {
        guard let zone = currentZone else { return [:] }
        return engine.collectionsForMonth(year: year, month: month, zone: zone)
    }

    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Month navigation
                HStack {
                    Button(action: previousMonth) {
                        Image(systemName: "chevron.left")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(monthName)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    Button(action: nextMonth) {
                        Image(systemName: "chevron.right")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)

                // Day of week headers
                HStack(spacing: 0) {
                    ForEach(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], id: \.self) { day in
                        Text(day)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)

                // Calendar grid
                calendarGrid
                    .padding(.horizontal, 12)

                Spacer()

                // Legend
                legend
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }
            .background(
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
            )
            .navigationTitle(String(localized: "Schedule"))
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedDate) { date in
                DayDetailView(date: date, zone: currentZone)
                    .presentationDetents([.medium])
            }
        }
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        let daysInMonth = calendar.range(of: .day, in: .month, for: displayedMonth)!.count
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        let firstDayDate = calendar.date(from: components)!
        let firstWeekday = calendar.component(.weekday, from: firstDayDate)
        // Convert to Monday-start: Mon=0, Tue=1, ... Sun=6
        let startOffset = (firstWeekday + 5) % 7

        let totalCells = startOffset + daysInMonth
        let rows = (totalCells + 6) / 7

        return VStack(spacing: 4) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { col in
                        let index = row * 7 + col
                        let day = index - startOffset + 1

                        if day >= 1 && day <= daysInMonth {
                            dayCell(day: day)
                        } else {
                            Color.clear
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                        }
                    }
                }
            }
        }
    }

    private func dayCell(day: Int) -> some View {
        let bins = monthCollections[day] ?? []
        let isToday = isTodayCheck(day: day)

        return Button {
            var components = DateComponents()
            components.year = year
            components.month = month
            components.day = day
            selectedDate = calendar.date(from: components)
        } label: {
            VStack(spacing: 4) {
                Text("\(day)")
                    .font(.system(size: 14, weight: isToday ? .bold : .regular))
                    .foregroundStyle(isToday ? .green : .primary)

                HStack(spacing: 3) {
                    ForEach(bins) { bin in
                        Circle()
                            .fill(bin.color)
                            .frame(width: 6, height: 6)
                    }
                }
                .frame(height: 8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isToday ? Color.green.opacity(0.15) : Color.clear)
            )
        }
    }

    private var legend: some View {
        HStack(spacing: 20) {
            ForEach(BinType.allCases.filter { $0 != .inorganic }) { bin in
                HStack(spacing: 6) {
                    Circle()
                        .fill(bin.color)
                        .frame(width: 8, height: 8)
                    Text(bin.displayName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Helpers

    private func isTodayCheck(day: Int) -> Bool {
        let today = Date()
        return calendar.component(.year, from: today) == year
            && calendar.component(.month, from: today) == month
            && calendar.component(.day, from: today) == day
    }

    private func previousMonth() {
        displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
    }

    private func nextMonth() {
        displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
    }
}

// MARK: - Date extension for sheet

extension Date: @retroactive Identifiable {
    public var id: TimeInterval { timeIntervalSince1970 }
}

// MARK: - Day Detail Sheet

struct DayDetailView: View {
    let date: Date
    let zone: CollectionZone?

    private let engine = ScheduleEngine()

    private var collections: [BinType] {
        guard let zone = zone else { return [] }
        return engine.binsCollectedOn(date: date, zone: zone)
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(spacing: 20) {
            // Handle / header
            RoundedRectangle(cornerRadius: 3)
                .fill(.gray.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 12)

            Text(dateString)
                .font(.headline)

            if collections.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle")
                        .font(.largeTitle)
                        .foregroundStyle(.green.opacity(0.5))
                    Text(String(localized: "No collection on this day"))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(collections) { bin in
                        HStack(spacing: 16) {
                            Text(bin.icon)
                                .font(.title)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(bin.displayName)
                                    .font(.body.weight(.semibold))
                                Text(bin.acceptedItems.prefix(3).joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(bin.color.opacity(0.1))
                        )
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer()
        }
    }
}
