import SwiftUI

/// The same per-bin editor is used for setup and later corrections.
struct ManualScheduleView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var schedules: [CollectionSchedule]
    @State private var enabled: Set<BinType>
    @State private var confirmed = false
    @State private var showCouncil = false
    let intro: String?
    let onSave: (CollectionZone) -> Void

    init(initialZone: CollectionZone? = nil, intro: String? = nil, onSave: @escaping (CollectionZone) -> Void) {
        self.onSave = onSave
        self.intro = intro
        let calendar = ScheduleEngine.collectionCalendar
        let nextDate = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: Date())!)
        let bins: [BinType] = [.rubbish, .recycling, .foodScraps]
        _schedules = State(initialValue: bins.map { bin in
            initialZone?.schedules.first(where: { $0.binType == bin })
                ?? CollectionSchedule(id: bin.rawValue, binType: bin, frequency: bin == .recycling ? .fortnightly : .weekly, anchorDate: nextDate)
        })
        _enabled = State(initialValue: Set(initialZone?.schedules.map(\.binType) ?? bins))
    }

    private var zone: CollectionZone { DataService.shared.manualZone(schedules: schedules.filter { enabled.contains($0.binType) }) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if let intro { Text(intro).font(.headline) }
                    Text(L("Check the regular collection dates for your property, then set each bin below. Add holiday or disruption changes separately."))
                    Button(L("Check dates with Auckland Council")) { showCouncil = true }
                    Text(L("Dates and reminder times use Auckland time. Address search does not verify collection dates."))
                        .font(.footnote).foregroundStyle(.secondary)
                }
                ForEach($schedules) { $schedule in
                    Section {
                        Toggle(isOn: Binding(get: { enabled.contains(schedule.binType) }, set: { value in
                            if value { enabled.insert(schedule.binType) } else { enabled.remove(schedule.binType) }
                            confirmed = false
                        })) { Label(schedule.binType.displayName, systemImage: schedule.binType.systemImage) }
                        if enabled.contains(schedule.binType) {
                            Picker(L("Frequency"), selection: $schedule.frequency) {
                                Text(L("Weekly")).tag(Frequency.weekly)
                                Text(L("Fortnightly")).tag(Frequency.fortnightly)
                            }
                            Picker(L("Collection day"), selection: weekdayBinding($schedule)) {
                                ForEach(1...7, id: \.self) { Text(Self.weekdayName($0)).tag($0) }
                            }
                            if schedule.frequency == .fortnightly {
                                let options = Self.nextDateOptions(for: schedule)
                                Picker(L("Next collection"), selection: nextDateBinding($schedule, options: options)) {
                                    ForEach(options, id: \.self) { Text($0, format: .dateTime.weekday(.abbreviated).day().month()).tag($0) }
                                }
                                .pickerStyle(.segmented)
                            }
                            let preview = ScheduleEngine().upcomingCollections(for: DataService.shared.manualZone(schedules: [schedule]), from: Date(), count: 2)
                            ForEach(preview) { collection in
                                Text(collection.date, format: .dateTime.weekday(.wide).day().month())
                                    .font(.subheadline).foregroundStyle(.secondary)
                            }
                            NavigationLink(L("One-off changes (%d)", schedule.changes.count)) {
                                CollectionChangesView(schedule: $schedule)
                            }
                        }
                    }
                }
                Section {
                    Toggle(L("These dates look right"), isOn: $confirmed)
                    if !zone.isValid { Text(L("Check each bin's collection date and frequency before saving.")).foregroundStyle(.red) }
                }
            }
            .navigationTitle(L("Your bin schedule"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(L("Cancel")) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("Save")) { onSave(zone); dismiss() }.disabled(!zone.isValid || !confirmed)
                }
            }
            .onChange(of: schedules) { _, _ in confirmed = false }
            .sheet(isPresented: $showCouncil) { SafariView(url: DataService.collectionURL).ignoresSafeArea() }
        }
        .environment(\.calendar, ScheduleEngine.collectionCalendar)
        .environment(\.timeZone, ScheduleEngine.collectionCalendar.timeZone)
    }

    // MARK: - Guided date selection

    /// Monday = 1 … Sunday = 7, in the collection calendar.
    static func weekday(of date: Date) -> Int {
        let day = ScheduleEngine.collectionCalendar.component(.weekday, from: date)
        return day == 1 ? 7 : day - 1
    }

    static func weekdayName(_ weekday: Int) -> String {
        var calendar = ScheduleEngine.collectionCalendar
        calendar.locale = LanguageManager.shared.locale
        return calendar.standaloneWeekdaySymbols[weekday % 7]
    }

    /// The first date on or after today with the given weekday.
    static func nextDate(weekday: Int, from reference: Date = Date()) -> Date {
        let calendar = ScheduleEngine.collectionCalendar
        let start = calendar.startOfDay(for: reference)
        let delta = (weekday - Self.weekday(of: start) + 7) % 7
        return calendar.date(byAdding: .day, value: delta, to: start)!
    }

    /// For fortnightly bins: the next two occurrences of the schedule's weekday. One of them is the next collection.
    static func nextDateOptions(for schedule: CollectionSchedule) -> [Date] {
        let first = nextDate(weekday: weekday(of: schedule.anchorDate))
        return [first, ScheduleEngine.collectionCalendar.date(byAdding: .day, value: 7, to: first)!]
    }

    /// Re-anchors a schedule on a date that keeps the cycle valid. Past one-off changes no longer apply and are dropped.
    static func reanchored(_ schedule: CollectionSchedule, to anchor: Date) -> CollectionSchedule {
        var updated = schedule
        updated.anchorDate = anchor
        updated.changes.removeAll { $0.originalDate < anchor }
        return updated
    }

    private func weekdayBinding(_ schedule: Binding<CollectionSchedule>) -> Binding<Int> {
        Binding(
            get: { Self.weekday(of: schedule.wrappedValue.anchorDate) },
            set: { schedule.wrappedValue = Self.reanchored(schedule.wrappedValue, to: Self.nextDate(weekday: $0)) }
        )
    }

    private func nextDateBinding(_ schedule: Binding<CollectionSchedule>, options: [Date]) -> Binding<Date> {
        Binding(
            get: { options.first { schedule.wrappedValue.isRegularCollection(on: $0) } ?? options[0] },
            set: { schedule.wrappedValue = Self.reanchored(schedule.wrappedValue, to: $0) }
        )
    }
}

private struct CollectionChangesView: View {
    @Binding var schedule: CollectionSchedule
    @State private var originalDate = Date()
    @State private var replacementDate = Date()
    @State private var skip = false
    @State private var error: String?

    var body: some View {
        Form {
            Section {
                Text(L("Move or skip one collection. The regular weekly or fortnightly cycle stays the same."))
                DatePicker(L("Original collection date"), selection: $originalDate, displayedComponents: .date)
                Toggle(L("Skip this collection"), isOn: $skip)
                if !skip { DatePicker(L("New collection date"), selection: $replacementDate, displayedComponents: .date) }
                Button(L("Add change")) { addChange() }
                if let error { Text(error).foregroundStyle(.red) }
            }
            Section(L("Saved changes")) {
                ForEach(schedule.changes.sorted { $0.originalDate < $1.originalDate }) { change in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(change.originalDate, style: .date)
                        if let replacement = change.replacementDate {
                            Text(L("Moved to %@", dateLabel(replacement)))
                        } else { Text(L("Skipped")) }
                        Button(L("Remove change"), role: .destructive) { schedule.changes.removeAll { $0.id == change.id } }
                    }
                }
            }
        }
        .navigationTitle(L("One-off changes"))
        .onAppear {
            let base = CollectionZone(id: "preview", name: "", suburbs: [], schedules: [CollectionSchedule(id: schedule.id, binType: schedule.binType, frequency: schedule.frequency, anchorDate: schedule.anchorDate)])
            originalDate = ScheduleEngine().nextCollection(for: base)?.date ?? schedule.anchorDate
            replacementDate = ScheduleEngine.collectionCalendar.date(byAdding: .day, value: 1, to: originalDate)!
        }
    }

    private func dateLabel(_ date: Date) -> String {
        let formatter = DateFormatter(); formatter.locale = LanguageManager.shared.locale
        formatter.timeZone = ScheduleEngine.collectionCalendar.timeZone; formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func addChange() {
        let calendar = ScheduleEngine.collectionCalendar
        let original = calendar.startOfDay(for: originalDate)
        var updated = schedule
        updated.changes.removeAll { calendar.isDate($0.originalDate, inSameDayAs: original) }
        updated.changes.append(CollectionDateChange(originalDate: original, replacementDate: skip ? nil : calendar.startOfDay(for: replacementDate)))
        guard updated.isValid else {
            error = L("Choose an original date in this bin's regular cycle and a new date without another collection.")
            return
        }
        schedule = updated; error = nil
    }
}
