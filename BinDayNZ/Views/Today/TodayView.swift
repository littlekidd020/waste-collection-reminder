import SwiftUI
import SwiftData

/// The main home screen — shows today's/upcoming collections with colourful bin cards.
struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var showChangeAddress = false

    private let engine = ScheduleEngine()
    private let dataService = DataService.shared

    private var profile: UserProfile? { profiles.first }

    private var currentZone: CollectionZone? {
        guard let profile = profile,
              let councilId = profile.councilId,
              let zoneId = profile.zoneId else { return nil }
        return dataService.zone(withId: zoneId, in: councilId)
    }

    private var todaysCollections: [BinType] {
        guard let zone = currentZone else { return [] }
        return engine.todaysCollections(zone: zone)
    }

    private var tomorrowsCollections: [BinType] {
        guard let zone = currentZone else { return [] }
        return engine.tomorrowsCollections(zone: zone)
    }

    private var upcoming: [UpcomingCollection] {
        guard let zone = currentZone else { return [] }
        return engine.upcomingCollections(for: zone, from: Date(), count: 10)
    }

    private var displayAddress: String {
        profile?.address ?? "Set your address"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Address pill
                    addressPill

                    // Hero section
                    heroSection

                    // Tomorrow preview
                    if !tomorrowsCollections.isEmpty {
                        tomorrowSection
                    }

                    // Upcoming list
                    upcomingSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(
                Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            )
            .navigationTitle(String(localized: "Today"))
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showChangeAddress) {
                ChangeAddressView()
            }
        }
    }

    // MARK: - Address Pill

    private var addressPill: some View {
        Button {
            showChangeAddress = true
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundStyle(.green)

                    Text(displayAddress)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                
                if let zone = currentZone {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.caption)
                            .foregroundStyle(.green)
                        
                        Text(zone.name)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.leading, 24) // Align with text above
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Sections

    @ViewBuilder
    private var heroSection: some View {
        if todaysCollections.isEmpty {
            // No collection today
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.green.opacity(0.6))
                    .symbolEffect(.pulse)

                Text(String(localized: "No collection today"))
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(String(localized: "Enjoy your day! 🌤️"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            )
        } else {
            // Collection today!
            VStack(spacing: 16) {
                Text(String(localized: "Collection Today!"))
                    .font(.headline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 16) {
                    ForEach(todaysCollections) { bin in
                        BinCard(binType: bin, label: String(localized: "Today"))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var tomorrowSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Tomorrow"))
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                ForEach(tomorrowsCollections) { bin in
                    BinCard(binType: bin, label: String(localized: "Tomorrow"), compact: true)
                }
            }
        }
    }

    @ViewBuilder
    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Upcoming"))
                .font(.headline)
                .foregroundStyle(.secondary)

            ForEach(upcoming) { collection in
                HStack(spacing: 16) {
                    // Bin icon
                    Image(systemName: collection.binType.systemImage)
                        .font(.title3)
                        .foregroundStyle(collection.binType.color)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(collection.binType.color.opacity(0.15))
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(collection.binType.displayName)
                            .font(.body.weight(.medium))
                            .foregroundStyle(.primary)
                        Text(collection.relativeLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if collection.isToday {
                        Text(String(localized: "Today"))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule().fill(.green.opacity(0.15))
                            )
                    } else if collection.isTomorrow {
                        Text(String(localized: "Tomorrow"))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule().fill(.orange.opacity(0.15))
                            )
                    } else {
                        Text("\(collection.daysUntil)d")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                )
            }
        }
    }
}

// MARK: - BinCard

/// A colourful card displaying a bin type with gradient background.
struct BinCard: View {
    let binType: BinType
    let label: String
    var compact: Bool = false

    var body: some View {
        VStack(spacing: compact ? 8 : 12) {
            Text(binType.icon)
                .font(.system(size: compact ? 28 : 40))

            VStack(spacing: 4) {
                Text(binType.displayName)
                    .font(compact ? .caption.weight(.semibold) : .subheadline.weight(.semibold))
                    .foregroundStyle(.white)

                if !compact {
                    Text(label)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, compact ? 16 : 24)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(binType.gradient)
                .shadow(color: binType.color.opacity(0.3), radius: 8, y: 4)
        )
    }
}
