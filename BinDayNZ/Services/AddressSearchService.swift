import Foundation
import MapKit
import Combine

/// Observable service that provides real-time address autocomplete using Apple MapKit.
/// Scoped to New Zealand for relevant results.
@MainActor
final class AddressSearchService: NSObject, ObservableObject {

    @Published var suggestions: [AddressSuggestion] = []
    @Published var isSearching = false

    private let completer = MKLocalSearchCompleter()
    private let dataService = DataService.shared

    override init() {
        super.init()
        completer.delegate = self
        // By relying on the default empty configuration (or broadly allowing points of interest + addresses), MapKit returns much more Uber-like robust suggestions.
        completer.resultTypes = [.address, .pointOfInterest]

        // Scope to New Zealand
        let nzRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -36.85, longitude: 174.76), // Auckland centre
            span: MKCoordinateSpan(latitudeDelta: 12.0, longitudeDelta: 12.0) // Cover all NZ
        )
        completer.region = nzRegion
    }

    /// Update the search query — triggers autocomplete.
    func search(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            suggestions = []
            isSearching = false
            return
        }
        isSearching = true
        completer.queryFragment = trimmed
    }

    /// Resolve a suggestion to a full address + coordinate.
    func resolve(_ suggestion: AddressSuggestion) async -> ResolvedAddress? {
        let request = MKLocalSearch.Request(completion: suggestion.completion)
        // Removed request.resultTypes = .address to allow resolving Point of Interest suggestions

        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()

            guard let item = response.mapItems.first,
                  let placemark = item.placemark as? MKPlacemark? else { return nil }

            let streetAddress = [
                placemark?.subThoroughfare,
                placemark?.thoroughfare
            ].compactMap { $0 }.joined(separator: " ")

            var suburb = placemark?.subLocality ?? placemark?.locality ?? ""
            let city = placemark?.locality ?? placemark?.administrativeArea ?? ""
            
            // Fallback: If MapKit subLocality is empty, try extracting from the subtitle
            if suburb.isEmpty && !suggestion.subtitle.isEmpty {
                let parts = suggestion.subtitle.components(separatedBy: ",")
                if let firstPart = parts.first {
                    suburb = firstPart.trimmingCharacters(in: .whitespaces)
                }
            }

            let fullAddress = [streetAddress, suburb, city].filter { !$0.isEmpty }.joined(separator: ", ")

            // Try to auto-detect zone from suburb
            let matchedZone = dataService.zoneForSuburb(suburb)

            return ResolvedAddress(
                fullAddress: fullAddress.isEmpty ? suggestion.title : fullAddress,
                suburb: suburb,
                city: city,
                matchedZone: matchedZone,
                coordinate: item.placemark.coordinate
            )
        } catch {
            print("⚠️ Address resolution failed: \(error)")
            return nil
        }
    }
}

// MARK: - MKLocalSearchCompleterDelegate

extension AddressSearchService: MKLocalSearchCompleterDelegate {
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let results = completer.results
        Task { @MainActor in
            self.suggestions = results.map { result in
                AddressSuggestion(
                    title: result.title,
                    subtitle: result.subtitle,
                    completion: result
                )
            }
            self.isSearching = false
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in
            self.isSearching = false
        }
    }
}

// MARK: - Models

struct AddressSuggestion: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let completion: MKLocalSearchCompletion
}

struct ResolvedAddress {
    let fullAddress: String
    let suburb: String
    let city: String
    let matchedZone: CollectionZone?
    let coordinate: CLLocationCoordinate2D
}
