import Foundation

/// Fixed sample data so every screenshot shows the same moment: Monday 9 November 2026, 5:30 pm in Auckland.
/// The household is in Mount Eden, Auckland: rubbish and food scraps weekly, recycling fortnightly, all on Tuesdays.
enum Sample {
    static let timeZone = TimeZone(identifier: "Pacific/Auckland")!
    static var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = timeZone
        c.locale = Locale(identifier: "en_NZ")
        c.firstWeekday = 2
        return c
    }

    static func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 0, _ min: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    static let now = date(2026, 11, 9, 17, 30)
    static let address = "14 Valley Road, Mount Eden"
    static let council = "Auckland Council"
    static let putOutBy = "7 am"

    struct Collection: Identifiable, Hashable {
        let date: Date
        let bins: [Bin]
        var id: Date { date }
    }

    /// The next eight collection days. Recycling is on the "A" fortnight; 10 November is an A week.
    static let collections: [Collection] = {
        var out: [Collection] = []
        var d = date(2026, 11, 10)
        for i in 0..<8 {
            let bins: [Bin] = i.isMultiple(of: 2) ? [.recycling, .rubbish, .foodScraps] : [.rubbish, .foodScraps]
            out.append(Collection(date: d, bins: bins))
            d = calendar.date(byAdding: .day, value: 7, to: d)!
        }
        return out
    }()

    static var next: Collection { collections[0] }

    /// The bins this council offers, for the Guide.
    static let guideBins: [Bin] = [.rubbish, .recycling, .foodScraps]

    static let holidayNotice = "Christmas week: collections run one day later from Friday 25 December."

    /// Short reasons, one per bin, used as guide blurbs.
    static func blurb(_ bin: Bin) -> String {
        switch bin {
        case .rubbish: return "Anything that cannot be recycled or composted. Bag it, keep the lid closed."
        case .recycling: return "Rinsed plastics 1, 2 and 5, tins and cans, paper and cardboard. Loose, lids off."
        case .foodScraps: return "All food, cooked or raw, bones included. Liner optional, compostable only."
        case .glass: return "Bottles and jars, rinsed, lids off. Loose in the crate, not bagged."
        }
    }

    static func accepted(_ bin: Bin) -> [String] {
        switch bin {
        case .rubbish: return ["Nappies and sanitary products", "Soft plastics and wraps", "Polystyrene", "Broken glass and ceramics", "Cold ashes"]
        case .recycling: return ["Plastic bottles and containers 1, 2, 5", "Tins and aluminium cans", "Paper and cardboard", "Pizza boxes, clean", "Glass bottles and jars"]
        case .foodScraps: return ["Fruit and vegetable scraps", "Meat, fish and bones", "Bread, rice and pasta", "Eggshells and coffee grounds", "Tea bags without plastic"]
        case .glass: return ["Glass bottles", "Glass jars", "Clear, green and brown glass"]
        }
    }

    static func refused(_ bin: Bin) -> [String] {
        switch bin {
        case .rubbish: return ["Recyclables", "Batteries and electronics", "Paint and chemicals", "Hot ashes", "Garden waste"]
        case .recycling: return ["Soft plastics", "Lids under 5 cm", "Takeaway coffee cups", "Food-soiled containers", "Drinking glasses and ceramics"]
        case .foodScraps: return ["Plastic bags", "Compostable packaging", "Garden waste", "Pet waste", "Liquids and oils"]
        case .glass: return ["Window glass", "Light bulbs", "Drinking glasses", "Ceramics"]
        }
    }
}

extension Sample {
    /// "Tonight", "Tomorrow" style relative phrase for the next collection, given the fixed `now`.
    static func relative(_ date: Date) -> String {
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: date)).day ?? 0
        switch days {
        case 0: return "Today"
        case 1: return "Tomorrow"
        default: return "In \(days) days"
        }
    }

    static func weekday(_ date: Date, short: Bool = false) -> String {
        let f = DateFormatter(); f.calendar = calendar; f.timeZone = timeZone; f.locale = Locale(identifier: "en_NZ")
        f.dateFormat = short ? "EEE" : "EEEE"
        return f.string(from: date)
    }

    static func dayNumber(_ date: Date) -> String {
        String(calendar.component(.day, from: date))
    }

    static func monthName(_ date: Date, short: Bool = false) -> String {
        let f = DateFormatter(); f.calendar = calendar; f.timeZone = timeZone; f.locale = Locale(identifier: "en_NZ")
        f.dateFormat = short ? "MMM" : "MMMM"
        return f.string(from: date)
    }

    /// "Recycling, rubbish and food scraps"
    static func list(_ bins: [Bin]) -> String {
        let names = bins.map { $0.name.lowercased() }
        guard names.count > 1 else { return names.first?.capitalized ?? "" }
        let head = names.dropLast().joined(separator: ", ")
        return (head + " and " + names.last!).prefix(1).uppercased() + (head + " and " + names.last!).dropFirst()
    }
}
