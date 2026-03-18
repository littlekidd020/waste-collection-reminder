import Foundation

struct CollectionZone: Codable {
    let id: String
    let name: String
    let suburbs: [String]
}

struct Council: Codable {
    let id: String
    let name: String
    let zones: [CollectionZone]
}

struct CouncilData: Codable {
    let version: Int
    let councils: [Council]
}

let url = URL(fileURLWithPath: "BinDayNZ/Resources/councils.json")
let data = try Data(contentsOf: url)
let decoder = JSONDecoder()
let councilData = try decoder.decode(CouncilData.self, from: data)

for council in councilData.councils {
    for zone in council.zones {
        for suburb in zone.suburbs {
            if suburb.localizedCaseInsensitiveCompare("Auckland CBD") == .orderedSame {
                print("Match found in zone: \(zone.name)")
            }
        }
    }
}
