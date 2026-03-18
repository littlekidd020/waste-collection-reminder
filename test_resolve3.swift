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
        guard let first = completer.results.first(where: { $0.title.contains("110") }) else {
            print("No results")
            done = true
            return
        }
        
        let request = MKLocalSearch.Request(completion: first)
        request.resultTypes = .address // The problematic line
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let error = error {
                print("Error with .address: \(error)")
            } else if let item = response?.mapItems.first {
                print("Resolved with .address: \(item.name ?? "unnamed")")
            } else {
                print("No map items with .address")
            }
            self.done = true
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        done = true
    }
}

let tester = Tester()
tester.search("110 queen")
while !tester.done { RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1)) }
