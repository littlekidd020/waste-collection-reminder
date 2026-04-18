import SwiftUI
import SwiftData
import MapKit
import CoreLocation

/// The main home screen — shows today's/upcoming collections with colourful bin cards.
struct TodayView: View {
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
        profile?.address ?? L("Set your address")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header / Address
                    VStack(spacing: 0) {
                        AddressPillView(
                            displayAddress: displayAddress,
                            currentZone: currentZone,
                            showChangeAddress: $showChangeAddress
                        )
                        .padding(.top, 16)
                    }

                    // Hero section
                    TodayHeroSectionView(todaysCollections: todaysCollections)

                    // Tomorrow preview
                    if !tomorrowsCollections.isEmpty {
                        TomorrowPreviewView(tomorrowsCollections: tomorrowsCollections)
                    }

                    // Upcoming list
                    UpcomingCollectionsView(upcoming: upcoming)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(
                ZStack {
                    Color(uiColor: .systemGroupedBackground)
                    
                    // Subtle map peek at the top to tie in the design
                    VStack {
                        if currentZone != nil {
                            // Default to Auckland center for the peek
                            MapPeekBackground(coordinate: CLLocationCoordinate2D(latitude: -36.8485, longitude: 174.7633))
                                .frame(height: 240)
                                .mask(
                                    LinearGradient(
                                        colors: [.black.opacity(0.18), .black.opacity(0.06), .clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .allowsHitTesting(false)
                        }
                        Spacer()
                    }
                }
                .ignoresSafeArea()
            )
            .navigationTitle(L("Today"))
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showChangeAddress) {
                ChangeAddressView()
            }
        }
    }
}

private struct MapPeekBackground: View {
    let coordinate: CLLocationCoordinate2D
    
    var body: some View {
        Map(initialPosition: .region(MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
        ))) {
            Marker("", coordinate: coordinate)
                .annotationTitles(.hidden)
        }
    }
}


// MARK: - Address Pill View

private struct AddressPillView: View {
    let displayAddress: String
    let currentZone: CollectionZone?
    @Binding var showChangeAddress: Bool

    var body: some View {
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
                        
                        Text(L(zone.name))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.leading, 24)
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
        .buttonStyle(.plain) // remove default button fading
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Sections

private struct TodayHeroSectionView: View {
    let todaysCollections: [BinType]

    var body: some View {
        if todaysCollections.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.green.opacity(0.6))
                    .symbolEffect(.pulse)

                Text(L("No collection today"))
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(L("Enjoy your day! 🌤️"))
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
            VStack(spacing: 16) {
                Text(L("Collection Today!"))
                    .font(.headline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 16) {
                    ForEach(todaysCollections) { bin in
                        BinCard(binType: bin, label: L("Today"))
                    }
                }
            }
        }
    }
}

private struct TomorrowPreviewView: View {
    let tomorrowsCollections: [BinType]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("Tomorrow"))
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                ForEach(tomorrowsCollections) { bin in
                    BinCard(binType: bin, label: L("Tomorrow"), compact: true)
                }
            }
        }
    }
}

private struct UpcomingCollectionsView: View {
    let upcoming: [UpcomingCollection]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("Upcoming"))
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(spacing: 0) {
                ForEach(upcoming) { collection in
                    HStack(spacing: 16) {
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
                            Text(L("Today"))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.green)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule().fill(.green.opacity(0.15))
                                )
                        } else if collection.isTomorrow {
                            Text(L("Tomorrow"))
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
                    
                    if collection.id != upcoming.last?.id {
                        Divider()
                            .padding(.leading, 70)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            )
        }
    }
}

// MARK: - BinCard

/// A colourful card displaying a bin type with gradient background.
struct BinCard: View {
    let binType: BinType
    let label: String
    var compact: Bool = false
    
    @State private var isVisible = false

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
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isVisible = true
            }
        }
    }
}
