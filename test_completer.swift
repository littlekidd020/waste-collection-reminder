import Foundation
import MapKit

class Tester: NSObject, MKLocalSearchCompleterDelegate {
    let completer = MKLocalSearchCompleter()
    var done = false
    
    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
        completer.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -36.85, longitude: 174.76),
            span: MKCoordinateSpan(latitudeDelta: 12.0, longitudeDelta: 12.0)
        )
    }
    
    func search(_ query: String) {
        completer.queryFragment = query
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        print("Got \(completer.results.count) results:")
        for r in completer.results {
            print("- \(r.title), \(r.subtitle)")
        }
        done = true
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Error: \(error)")
        done = true
    }
}

let tester = Tester()
tester.search("101 queen str")

while !tester.done {
    RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
}
