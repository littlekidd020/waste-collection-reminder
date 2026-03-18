import Foundation
import MapKit

class Tester: NSObject, MKLocalSearchCompleterDelegate {
    let completer = MKLocalSearchCompleter()
    var done = false
    
    override init() {
        super.init()
        completer.delegate = self
    }
    
    func search(_ query: String) {
        completer.queryFragment = query
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        guard let first = completer.results.first(where: { $0.title.contains("110 Queen") }) else {
            print("No results")
            done = true
            return
        }
        
        let request = MKLocalSearch.Request(completion: first)
        request.resultTypes = .address
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let item = response?.mapItems.first,
               let placemark = item.placemark as? MKPlacemark? {
                
                let suburb = placemark?.subLocality ?? placemark?.locality ?? ""
                let city = placemark?.locality ?? placemark?.administrativeArea ?? ""
                
                print("suburb resolved as: '\(suburb)'")
                print("city resolved as: '\(city)'")
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
tester.search("110 quee")

while !tester.done {
    RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
}
