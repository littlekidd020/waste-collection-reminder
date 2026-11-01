import Foundation

/// Represents a single upcoming bin collection event.
struct UpcomingCollection: Identifiable, Equatable {
    var id: String { "\(binType.rawValue)-\(date.timeIntervalSince1970)" }
    let binType: BinType
    let date: Date
}
