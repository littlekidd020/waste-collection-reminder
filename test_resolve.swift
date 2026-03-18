import Foundation
import MapKit

class Tester: NSObject, MKLocalSearchCompleterDelegate {
    let completer = MKLocalSearchCompleter()
    var done = false
    
    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }
    
    func search(_ query: String) {
        completer.queryFragment = query
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        guard let first = completer.results.first else {
            print("No results")
            done = true
            return
        }
        
        let req = MKLocalSearch.Request(completion: first)
        let search = MKLocalSearch(request: req)
        search.start { resp, err in
            if let item = resp?.mapItems.first {
                let p = item.placemark
                print("Address: \(p.title ?? "")")
                print("subThoroughfare: \(p.subThoroughfare ?? "")")
                print("thoroughfare: \(p.thoroughfare ?? "")")
                print("subLocality: \(p.subLocality ?? "")")
                print("locality: \(p.locality ?? "")")
                print("administrativeArea: \(p.administrativeArea ?? "")")
            }
            self.done = true
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Error: \(error)")
        done = true
    }
}

let tester = Tester()
tester.search("110 Queen St")

while !tester.done {
    RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
}
