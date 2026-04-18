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

            // Try to auto-detect zone from suburb, with fallback to locality/subtitle
            var matchedZone = dataService.zoneForSuburb(suburb)
            
            // Fallback: try locality (broader area) if suburb didn't match
            if matchedZone == nil, let locality = placemark?.locality, locality != suburb {
                matchedZone = dataService.zoneForSuburb(locality)
            }
            
            // Fallback: try subLocality directly if it differs from what we used
            if matchedZone == nil, let subLocality = placemark?.subLocality, subLocality != suburb {
                matchedZone = dataService.zoneForSuburb(subLocality)
            }
            
            // Fallback: try parts of the suggestion subtitle (often has "Takanini, Auckland")
            if matchedZone == nil, !suggestion.subtitle.isEmpty {
                let subtitleParts = suggestion.subtitle.components(separatedBy: ",")
                for part in subtitleParts {
                    let candidate = part.trimmingCharacters(in: .whitespaces)
                    if !candidate.isEmpty, let zone = dataService.zoneForSuburb(candidate) {
                        matchedZone = zone
                        break
                    }
                }
            }

            // --- Live Auckland API Check ---
            // If the city/suburb indicates it's in Auckland, run the live lookup
            let searchTarget = fullAddress.isEmpty ? suggestion.title : fullAddress
            let isAuckland = city.localizedCaseInsensitiveContains("Auckland") || suburb.localizedCaseInsensitiveContains("Auckland") || suggestion.subtitle.localizedCaseInsensitiveContains("Auckland") || matchedZone?.id.hasPrefix("akl-") == true
            
            if isAuckland {
                if let dynamicZone = try? await resolveAucklandZone(for: searchTarget) {
                    matchedZone = dynamicZone
                }
            }

            return ResolvedAddress(
                fullAddress: searchTarget,
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

// MARK: - Live API Fetcher Extension

extension AddressSearchService {
    
    private func resolveAucklandZone(for addressQuery: String) async throws -> CollectionZone? {
        guard let encodedQuery = addressQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://experience.aucklandcouncil.govt.nz/nextapi/property?query=\(encodedQuery)&pageSize=5") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        struct SearchResponse: Codable {
            let items: [SearchItem]?
        }
        struct SearchItem: Codable {
            let id: String
            let address: String
        }
        let response = try JSONDecoder().decode(SearchResponse.self, from: data)
        guard let firstItem = response.items?.first else { return nil }
        
        return try await fetchSchedulePattern(assessmentId: firstItem.id)
    }
    
    private func fetchSchedulePattern(assessmentId: String) async throws -> CollectionZone? {
        guard let url = URL(string: "https://www.aucklandcouncil.govt.nz/en/rubbish-recycling/rubbish-recycling-collections/rubbish-recycling-collection-days/\(assessmentId).html") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let html = String(data: data, encoding: .utf8) else { return nil }
        
        let pattern = #"(Rubbish|Recycling):\s*<b[^>]*>\s*(\w+),\s*(\d+)\s+(\w+)"#
        let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let matches = regex.matches(in: html, options: [], range: NSRange(location: 0, length: html.utf16.count))
        
        var nextRubbishDate: Date?
        var nextRecyclingDate: Date?
        var dayOfWeek = 0
        
        let currentYear = Calendar.current.component(.year, from: Date())
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMMM yyyy"
        dateFormatter.locale = Locale(identifier: "en_NZ")
        
        for match in matches {
            guard match.numberOfRanges == 5,
                  let typeRange = Range(match.range(at: 1), in: html),
                  let dayRange = Range(match.range(at: 2), in: html),
                  let dateRange = Range(match.range(at: 3), in: html),
                  let monthRange = Range(match.range(at: 4), in: html) else { continue }
            
            let type = String(html[typeRange]).lowercased()
            let dateNum = String(html[dateRange])
            let monthString = String(html[monthRange])
            
            let dateStr = "\(dateNum) \(monthString) \(currentYear)"
            if let parsedDate = dateFormatter.date(from: dateStr) {
                let iosWeekday = Calendar.current.component(.weekday, from: parsedDate)
                let isoWeekday = iosWeekday == 1 ? 7 : iosWeekday - 1
                
                if type == "rubbish" {
                    nextRubbishDate = parsedDate
                    dayOfWeek = isoWeekday
                } else if type == "recycling" {
                    nextRecyclingDate = parsedDate
                }
            }
        }
        
        guard let recDate = nextRecyclingDate else { return nil }
        let isoWeek = Calendar.current.component(.weekOfYear, from: recDate)
        let parityStr = (isoWeek % 2 == 0) ? "even" : "odd"
        
        let dynamicZoneId = "akl-dynamic-\(dayOfWeek)-\(parityStr)"
        return dataService.zone(withId: dynamicZoneId, in: "auckland-council")
    }
}
