import Foundation
import CoreLocation
import Combine

@MainActor
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var isRequestingLocation = false
    @Published var locationError: String?

    private let manager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation?, Error>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestCurrentLocationAddress() async throws -> String? {
        isRequestingLocation = true
        locationError = nil

        defer { isRequestingLocation = false }

        let status = manager.authorizationStatus
        if status == .denied || status == .restricted {
            throw NSError(domain: "LocationManager", code: 1, userInfo: [NSLocalizedDescriptionKey: String(localized: "Location access denied. Please enable in Settings.")])
        }

        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
            // We need to wait for the authorization status to change.
            // For simplicity, we'll try to request location anyway, but if it fails, the user will need to tap again next time.
        }

        let location: CLLocation? = try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            manager.requestLocation()
        }

        guard let location = location else { return nil }

        // Reverse geocode
        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        guard let placemark = placemarks.first else { return nil }

        let streetAddress = [
            placemark.subThoroughfare,
            placemark.thoroughfare
        ].compactMap { $0 }.joined(separator: " ")

        let suburb = placemark.subLocality ?? placemark.locality ?? ""
        let city = placemark.locality ?? placemark.administrativeArea ?? ""

        let fullAddress = [streetAddress, suburb, city].filter { !$0.isEmpty }.joined(separator: ", ")
        
        return fullAddress.isEmpty ? nil : fullAddress
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            if let continuation = locationContinuation {
                continuation.resume(returning: locations.first)
                locationContinuation = nil
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            // CLError.locationUnknown can be ignored as the manager will keep trying
            if let clError = error as? CLError, clError.code == .locationUnknown {
                return
            }
            self.locationError = error.localizedDescription
            if let continuation = locationContinuation {
                continuation.resume(throwing: error)
                locationContinuation = nil
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
                if locationContinuation != nil {
                    manager.requestLocation()
                }
            } else if manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted {
                if let continuation = locationContinuation {
                    let error = NSError(domain: "LocationManager", code: 1, userInfo: [NSLocalizedDescriptionKey: String(localized: "Location access denied.")])
                    continuation.resume(throwing: error)
                    locationContinuation = nil
                }
            }
        }
    }
}
