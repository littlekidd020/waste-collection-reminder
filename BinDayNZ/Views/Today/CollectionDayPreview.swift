import SwiftUI
import CoreLocation

/// A preview-only view to demonstrate how TodayView looks with different collection types.
struct CollectionDayPreview: View {
    let mockTodaysCollections: [BinType]
    let mockTomorrowsCollections: [BinType]
    let mockUpcoming: [UpcomingCollection]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header / Address
                    VStack(spacing: 0) {
                        AddressPillPreview()
                        .padding(.top, 16)
                    }

                    // Hero section
                    TodayHeroSectionPreview(todaysCollections: mockTodaysCollections)

                    // Tomorrow preview
                    if !mockTomorrowsCollections.isEmpty {
                        TomorrowPreviewPreview(tomorrowsCollections: mockTomorrowsCollections)
                    }

                    // Upcoming list
                    UpcomingCollectionsPreview(upcoming: mockUpcoming)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(
                ZStack {
                    Color(uiColor: .systemGroupedBackground)
                    VStack {
                        Rectangle()
                            .fill(.green.opacity(0.1))
                            .frame(height: 240)
                            .mask(
                                LinearGradient(
                                    colors: [.black.opacity(0.18), .black.opacity(0.06), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        Spacer()
                    }
                }
                .ignoresSafeArea()
            )
            .navigationTitle("Today")
        }
    }
}

// MARK: - Mock Components (Extracted from TodayView for preview)

private struct AddressPillPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "location.fill")
                    .font(.caption)
                    .foregroundStyle(.green)

                Text("123 Auckland Road")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TodayHeroSectionPreview: View {
    let todaysCollections: [BinType]

    var body: some View {
        if todaysCollections.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.green.opacity(0.6))

                Text("No collection today")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("Enjoy your day! 🌤️")
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
                Text("Collection Today!")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 16) {
                    ForEach(todaysCollections) { bin in
                        BinCard(binType: bin, label: "Today")
                    }
                }
            }
        }
    }
}

private struct TomorrowPreviewPreview: View {
    let tomorrowsCollections: [BinType]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tomorrow")
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                ForEach(tomorrowsCollections) { bin in
                    BinCard(binType: bin, label: "Tomorrow", compact: true)
                }
            }
        }
    }
}

private struct UpcomingCollectionsPreview: View {
    let upcoming: [UpcomingCollection]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming")
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(spacing: 0) {
                ForEach(upcoming) { collection in
                    HStack(spacing: 16) {
                        Image(systemName: collection.binType.systemImage)
                            .font(.title3)
                            .foregroundStyle(collection.binType.color)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(collection.binType.color.opacity(0.15)))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(collection.binType.displayName)
                                .font(.body.weight(.medium))
                            Text(collection.relativeLabel)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .padding(14)
                    
                    if collection.id != upcoming.last?.id {
                        Divider().padding(.leading, 70)
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

// MARK: - Previews

#Preview("No Collection Today") {
    CollectionDayPreview(
        mockTodaysCollections: [],
        mockTomorrowsCollections: [],
        mockUpcoming: [
            UpcomingCollection(binType: .foodScraps, date: Date().addingTimeInterval(86400 * 3)),
            UpcomingCollection(binType: .rubbish, date: Date().addingTimeInterval(86400 * 7))
        ]
    )
}

#Preview("Rubbish & Recycling Today") {
    CollectionDayPreview(
        mockTodaysCollections: [.rubbish, .recycling],
        mockTomorrowsCollections: [],
        mockUpcoming: [
            UpcomingCollection(binType: .foodScraps, date: Date().addingTimeInterval(86400 * 7))
        ]
    )
}

#Preview("Food Scraps Tomorrow") {
    CollectionDayPreview(
        mockTodaysCollections: [],
        mockTomorrowsCollections: [.foodScraps],
        mockUpcoming: [
            UpcomingCollection(binType: .foodScraps, date: Date().addingTimeInterval(86400 * 1)),
            UpcomingCollection(binType: .rubbish, date: Date().addingTimeInterval(86400 * 7))
        ]
    )
}
