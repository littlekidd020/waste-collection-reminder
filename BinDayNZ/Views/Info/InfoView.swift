import SwiftUI
import MapKit
import SwiftData

/// Info view — bin guide, location map, and tips.
struct InfoView: View {
    @Query private var profiles: [UserProfile]
    @State private var selectedBin: BinType?
    @State private var headerVisible = false

    private let dataService = DataService.shared

    private var profile: UserProfile? { profiles.first }

    private var currentZone: CollectionZone? {
        guard let profile = profile,
              let councilId = profile.councilId,
              let zoneId = profile.zoneId else { return nil }
        return dataService.zone(withId: zoneId, in: councilId)
    }

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Location map hero
                    LocationMapSection(
                        profile: profile,
                        zone: currentZone,
                        isVisible: $headerVisible
                    )

                    // Bin guides
                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeader(
                            title: L("Bin Guide"),
                            icon: "trash.circle.fill",
                            color: .green
                        )

                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(BinType.allCases) { binType in
                                BinGuideCard(binType: binType) {
                                    selectedBin = binType
                                }
                            }
                        }
                    }

                    // Tips section
                    TipsSection()
                    
                    // Quick links
                    QuickLinksSection()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
            )
            .navigationTitle(L("Info"))
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedBin) { binType in
                BinDetailView(binType: binType)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                    headerVisible = true
                }
            }
        }
    }
}

// MARK: - Section Header

private struct SectionHeader: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .symbolRenderingMode(.hierarchical)

            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Location Map Section

private struct LocationMapSection: View {
    let profile: UserProfile?
    let zone: CollectionZone?
    @Binding var isVisible: Bool

    /// Default to Auckland CBD if no user location
    private var mapRegion: MKCoordinateRegion {
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -36.8485, longitude: 174.7633),
            span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // Map
            Map(initialPosition: .region(mapRegion)) {
                // User location marker
                if profile?.address != nil {
                    Annotation("", coordinate: mapRegion.center) {
                        ZStack {
                            Circle()
                                .fill(.green.opacity(0.2))
                                .frame(width: 48, height: 48)

                            Circle()
                                .fill(.green.opacity(0.4))
                                .frame(width: 28, height: 28)

                            Circle()
                                .fill(.green)
                                .frame(width: 14, height: 14)
                                .shadow(color: .green.opacity(0.5), radius: 6)
                        }
                    }
                }
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
            .frame(height: 180)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 20,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 20
                )
            )
            .allowsHitTesting(false) // Prevent map interaction stealing scrolls

            // Location info overlay
            VStack(spacing: 10) {
                if let address = profile?.address, !address.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "location.fill")
                            .font(.subheadline)
                            .foregroundStyle(.green)

                        Text(address)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                        
                        Spacer()
                    }
                }

                if let zone = zone {
                    HStack(spacing: 10) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.subheadline)
                            .foregroundStyle(.green)

                        Text(L(zone.name))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text(L("Your zone"))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule().fill(.green.opacity(0.12))
                            )
                    }
                }
                
                if profile?.address == nil || profile?.address?.isEmpty == true {
                    HStack(spacing: 10) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text(L("Set your address in Today to see your zone"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                    }
                }
            }
            .padding(16)
            .background(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 20,
                    bottomTrailingRadius: 20,
                    topTrailingRadius: 0
                )
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
            )
        }
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
        .opacity(isVisible ? 1.0 : 0.0)
        .offset(y: isVisible ? 0 : 12)
    }
}

// MARK: - Tips Section

private struct TipsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                title: L("Tips"),
                icon: "lightbulb.fill",
                color: .yellow
            )

            VStack(spacing: 2) {
                TipRow(
                    icon: "clock.fill",
                    iconColor: .orange,
                    title: L("Put bins out the night before"),
                    detail: L("Collection starts early! Have your bin at the kerb by 7am.")
                )

                TipRow(
                    icon: "arrow.up.to.line.compact",
                    iconColor: .red,
                    title: L("Lid must close"),
                    detail: L("Bins with lids that don't close won't be collected.")
                )

                TipRow(
                    icon: "drop.fill",
                    iconColor: .blue,
                    title: L("Rinse containers"),
                    detail: L("Quickly rinse food containers before recycling.")
                )

                TipRow(
                    icon: "wind",
                    iconColor: .teal,
                    title: L("Windy days"),
                    detail: L("Place your bin where it won't blow away. Consider weighting the lid.")
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            )
        }
    }
}

private struct TipRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(iconColor.gradient)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Quick Links Section

private struct QuickLinksSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                title: L("Resources"),
                icon: "link.circle.fill",
                color: .blue
            )
            
            VStack(spacing: 2) {
                QuickLinkRow(
                    icon: "globe",
                    title: L("Auckland Council Website"),
                    subtitle: L("Rubbish & recycling info"),
                    url: "https://www.aucklandcouncil.govt.nz/rubbish-recycling"
                )
                
                QuickLinkRow(
                    icon: "phone.fill",
                    title: L("Report a missed collection"),
                    subtitle: L("Contact your council"),
                    url: "tel:09-301-0101"
                )
                
                QuickLinkRow(
                    icon: "map.fill",
                    title: L("Find a recycling drop-off"),
                    subtitle: L("Community recycling centres"),
                    url: "https://www.aucklandcouncil.govt.nz/rubbish-recycling/Pages/community-recycling-centres.aspx"
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            )
        }
    }
}

private struct QuickLinkRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let url: String
    
    var body: some View {
        Button {
            if let url = URL(string: url) {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(.blue.gradient)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - BinGuideCard

/// Colourful card with gradient tint for each bin type.
struct BinGuideCard: View {
    let binType: BinType
    let onTap: () -> Void
    
    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Gradient header
                ZStack(alignment: .topTrailing) {
                    binType.gradient
                        .frame(height: 56)
                    
                    Image(systemName: binType.systemImage)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.3))
                        .padding(12)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    Text(binType.icon)
                        .font(.title)
                        .offset(y: -8)

                    Text(binType.displayName)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if binType == .inorganic {
                        Text(L("Special collection"))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    } else {
                        Text(L("Tap for details"))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
                
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 164)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: binType.color.opacity(0.15), radius: 8, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

/// Subtle press-scale animation for cards.
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - BinDetailView

private struct BinDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let binType: BinType
    
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Embedded video player
                    ZStack(alignment: .bottomTrailing) {
                        YouTubePlayerView(binType: binType)
                            .aspectRatio(16/9, contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .background(Color.black)

                        // Fallback: open in YouTube app / Safari
                        Button {
                            if let url = URL(string: binType.videoURL) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "play.rectangle.fill")
                                Text(L("Open on YouTube"))
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.black.opacity(0.6), in: Capsule())
                            .padding(12)
                        }
                    }

                    VStack(alignment: .leading, spacing: 28) {
                        // Header with icon and gradient accent
                        HStack(spacing: 18) {
                            Text(binType.icon)
                                .font(.system(size: 56))
                                .shadow(color: binType.color.opacity(0.3), radius: 8)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(binType.displayName)
                                    .font(.title2.bold())
                                    .foregroundStyle(.primary)

                                if binType == .inorganic {
                                    Text(L("Special collection"))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.top, 8)
                        
                        // Colour accent bar
                        binType.gradient
                            .frame(height: 4)
                            .clipShape(Capsule())

                        // Accepted items
                        DetailListSection(
                            title: L("Yes, put these in"),
                            icon: "checkmark.circle.fill",
                            iconColor: .green,
                            items: binType.acceptedItems,
                            itemIcon: "checkmark",
                            itemColor: .green
                        )

                        // Rejected items
                        DetailListSection(
                            title: L("Not in this bin"),
                            icon: "xmark.circle.fill",
                            iconColor: .red,
                            items: binType.rejectedItems,
                            itemIcon: "xmark",
                            itemColor: .red
                        )
                    }
                    .padding(24)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
            }
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .navigationTitle(binType.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("Done")) {
                        dismiss()
                    }
                    .foregroundStyle(.green)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.4).delay(0.15)) {
                    appeared = true
                }
            }
        }
    }
}

// MARK: - Detail List Section

private struct DetailListSection: View {
    let title: String
    let icon: String
    let iconColor: Color
    let items: [String]
    let itemIcon: String
    let itemColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label {
                Text(title)
                    .font(.headline)
            } icon: {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: itemIcon)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(itemColor.opacity(0.7))
                            .frame(width: 22, height: 22)
                            .background(
                                Circle().fill(itemColor.opacity(0.1))
                            )
                            .padding(.top, 1)
                        
                        Text(item)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.leading, 4)
        }
    }
}
