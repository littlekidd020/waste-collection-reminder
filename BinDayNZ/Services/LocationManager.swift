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
            throw NSError(domain: "LocationManager", code: 1, userInfo: [NSLocalizedDescriptionKey: L("Location access denied. Please enable in Settings.")])
        }

        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }

        let location: CLLocation? = try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            manager.requestLocation()
        }

        guard let location = location else { return nil }

        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        guard let placemark = placemarks.first else { return nil }

        var addressComponents: [String] = []

        if let subThoroughfare = placemark.subThoroughfare, !subThoroughfare.isEmpty {
            addressComponents.append(subThoroughfare)
        }

        if let thoroughfare = placemark.thoroughfare, !thoroughfare.isEmpty, placemark.subThoroughfare == nil {
            addressComponents.append(thoroughfare)
        }

        if let locality = placemark.subLocality ?? placemark.locality, !locality.isEmpty {
            addressComponents.append(locality)
        }

        if let administrativeArea = placemark.administrativeArea, !administrativeArea.isEmpty {
            if addressComponents.isEmpty || !addressComponents.last!.contains(administrativeArea) {
                addressComponents.append(administrativeArea)
            }
        }

        let fullAddress = addressComponents.filter { !$0.isEmpty }.joined(separator: ", ")

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
                    let error = NSError(domain: "LocationManager", code: 1, userInfo: [NSLocalizedDescriptionKey: L("Location access denied.")])
                    continuation.resume(throwing: error)
                    locationContinuation = nil
                }
            }
        }
    }
}
