import Foundation
import MapKit
import Combine

/// Apple Maps identifies a location only. Collection dates are always confirmed separately.
@MainActor
final class AddressSearchService: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var suggestions: [AddressSuggestion] = []
    @Published var isSearching = false
    @Published var errorMessage: String?
    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
        completer.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: -36.85, longitude: 174.76), span: MKCoordinateSpan(latitudeDelta: 1.5, longitudeDelta: 1.5))
    }

    func search(_ query: String) {
        errorMessage = nil
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= 3 else {
            completer.cancel()
            suggestions = []
            isSearching = false
            return
        }
        isSearching = true
        completer.queryFragment = query
    }

    func resolve(_ suggestion: AddressSuggestion) async throws -> ResolvedAddress {
        let request = MKLocalSearch.Request(completion: suggestion.completion)
        request.resultTypes = .address
        let response = try await MKLocalSearch(request: request).start()
        guard let item = response.mapItems.first, item.placemark.isoCountryCode == "NZ" else { throw AddressError.notFound }
        let street = [item.placemark.subThoroughfare, item.placemark.thoroughfare].compactMap { $0 }.joined(separator: " ")
        let parts = [street, item.placemark.subLocality, item.placemark.locality].compactMap { $0 }.filter { !$0.isEmpty }
        let address = parts.isEmpty ? suggestion.title : parts.reduce(into: [String]()) { if !$0.contains($1) { $0.append($1) } }.joined(separator: ", ")
        return ResolvedAddress(fullAddress: address, coordinate: item.placemark.coordinate)
    }

    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let results = completer.results
        Task { @MainActor in
            self.suggestions = results.map { AddressSuggestion(title: $0.title, subtitle: $0.subtitle, completion: $0) }
            self.isSearching = false
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in
            self.suggestions = []
            self.isSearching = false
            self.errorMessage = L("Address search is unavailable. You can still enter and confirm your schedule.")
        }
    }
}

struct AddressSuggestion: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let completion: MKLocalSearchCompletion
}
struct ResolvedAddress {
    let fullAddress: String
    let coordinate: CLLocationCoordinate2D
}
enum AddressError: LocalizedError {
    case notFound
    var errorDescription: String? { L("The address could not be found. Enter it yourself or continue without one.") }
}
