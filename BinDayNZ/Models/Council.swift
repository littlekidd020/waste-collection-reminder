import Foundation

/// One of New Zealand's regions, used to group councils in the picker and to pick the
/// anniversary day a council observes.
enum Region: String, CaseIterable, Identifiable, Codable {
    case northland, auckland, waikato, bayOfPlenty, gisborne, hawkesBay, taranaki, manawatuWhanganui
    case wellington, tasman, nelson, marlborough, westCoast, canterbury, otago, southland, chathamIslands

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .northland: return L("Northland")
        case .auckland: return L("Auckland")
        case .waikato: return L("Waikato")
        case .bayOfPlenty: return L("Bay of Plenty")
        case .gisborne: return L("Gisborne")
        case .hawkesBay: return L("Hawke's Bay")
        case .taranaki: return L("Taranaki")
        case .manawatuWhanganui: return L("Manawatū-Whanganui")
        case .wellington: return L("Wellington")
        case .tasman: return L("Tasman")
        case .nelson: return L("Nelson")
        case .marlborough: return L("Marlborough")
        case .westCoast: return L("West Coast")
        case .canterbury: return L("Canterbury")
        case .otago: return L("Otago")
        case .southland: return L("Southland")
        case .chathamIslands: return L("Chatham Islands")
        }
    }
}

/// The provincial anniversary day a council observes. Several regions share one.
enum AnniversaryDay: String, CaseIterable, Codable {
    case auckland, wellington, nelson, taranaki, otago, southland, southCanterbury
    case hawkesBay, marlborough, canterbury, chathamIslands, westland
}

/// How a council moves collections around public holidays. Only a rule read from the council's
/// own published notice is applied automatically; everything else links the notice instead.
enum HolidayPolicy: Hashable {
    /// Published rule: a collection on or after the holiday runs one day later for the rest of that week.
    case oneDayLaterThatWeek(source: URL)
    /// No verified rule is bundled. The app lists the affected dates and links the council's notice.
    case checkCouncil(source: URL)

    var sourceURL: URL {
        switch self {
        case .oneDayLaterThatWeek(let source), .checkCouncil(let source): return source
        }
    }

    var appliesAutomatically: Bool {
        if case .oneDayLaterThatWeek = self { return true }
        return false
    }
}

/// A territorial authority that runs or contracts kerbside collections. The app never fetches
/// dates from a council; the directory tells the household where the official dates are and
/// which bins the council offers. Review every release.
struct Council: Identifiable, Hashable {
    let id: String
    let name: String
    let region: Region
    let anniversary: AnniversaryDay
    /// The council's rubbish and recycling landing page.
    let website: URL
    /// Where the council publishes a property's collection day. Falls back to `website`.
    let collectionDayURL: URL
    /// Kerbside bins the council offers to most households, in display order.
    let services: [BinType]
    /// Localities and district names an Apple placemark may carry for addresses in this council.
    let matchTerms: [String]
    /// Main contact number, only where it has been checked; nil hides the call link.
    let phone: String?
    let holidayPolicy: HolidayPolicy
    /// Only the Chatham Islands keep a different clock; reminder times still use mainland time.
    let timeZoneIdentifier: String

    init(id: String, name: String, region: Region, anniversary: AnniversaryDay, website: String, collectionDay: String? = nil,
         services: [BinType], terms: [String], phone: String? = nil, holidayPolicy: HolidayPolicy? = nil,
         timeZoneIdentifier: String = "Pacific/Auckland") {
        self.id = id
        self.name = name
        self.region = region
        self.anniversary = anniversary
        let dayURL = URL(string: collectionDay ?? website)!
        self.website = URL(string: website)!
        self.collectionDayURL = dayURL
        self.services = services
        self.matchTerms = terms
        self.phone = phone
        self.holidayPolicy = holidayPolicy ?? .checkCouncil(source: dayURL)
        self.timeZoneIdentifier = timeZoneIdentifier
    }

    var usesMainlandTime: Bool { timeZoneIdentifier == "Pacific/Auckland" }

    /// A `tel:` link for the checked contact number, if any.
    var phoneURL: URL? {
        phone.flatMap { URL(string: "tel:" + $0.filter(\.isNumber)) }
    }

    static func == (lhs: Council, rhs: Council) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// Every New Zealand territorial authority. Links and services were compiled on 7–8 November 2026 from
/// each council's public rubbish and recycling pages (search listings where a site blocks automated readers); `reviewedOn` is the date to update when
/// the list is next checked against the councils.
enum CouncilDirectory {
    static let reviewedOn = DateComponents(calendar: Calendar(identifier: .gregorian), year: 2026, month: 11, day: 7).date!

    private static let aucklandHolidaySource = "https://www.aucklandcouncil.govt.nz/en/rubbish-recycling/rubbish-recycling-collections/public-holiday-collections.html"

    static let auckland = Council(
        id: "auckland-council", name: "Auckland Council", region: .auckland, anniversary: .auckland,
        website: "https://www.aucklandcouncil.govt.nz/rubbish-recycling",
        collectionDay: "https://www.aucklandcouncil.govt.nz/en/rubbish-recycling/rubbish-recycling-collections/rubbish-recycling-collection-days.html",
        services: [.rubbish, .recycling, .foodScraps, .inorganic],
        terms: ["Auckland", "Auckland Region", "Waiheke Island", "Great Barrier Island", "Aotea"],
        phone: "09 301 0101",
        holidayPolicy: .oneDayLaterThatWeek(source: URL(string: aucklandHolidaySource)!))

    static let all: [Council] = [
        // Northland
        Council(id: "far-north-district-council", name: "Far North District Council", region: .northland, anniversary: .auckland,
                website: "https://www.fndc.govt.nz/Services/Rubbish-and-Recycling",
                collectionDay: "https://www.fndc.govt.nz/Services/Rubbish-and-Recycling/Kerbside-rubbish-and-recycling-collections",
                services: [.rubbish, .recycling],
                terms: ["Far North", "Far North District", "Kaitaia", "Kerikeri", "Kaikohe", "Paihia", "Russell", "Kawakawa", "Mangonui"]),
        Council(id: "whangarei-district-council", name: "Whangārei District Council", region: .northland, anniversary: .auckland,
                website: "https://www.wdc.govt.nz/Services/Rubbish",
                collectionDay: "https://www.wdc.govt.nz/Services/Rubbish/Kerbside-collection",
                services: [.rubbish, .recycling],
                terms: ["Whangarei", "Whangārei", "Whangarei District", "Ruakaka", "Ruakākā", "Hikurangi", "Waipu"]),
        Council(id: "kaipara-district-council", name: "Kaipara District Council", region: .northland, anniversary: .auckland,
                website: "https://www.kaipara.govt.nz/rubbish-recycling",
                collectionDay: "https://www.kaipara.govt.nz/rubbish-day-search",
                services: [.rubbish, .recycling],
                terms: ["Kaipara", "Kaipara District", "Dargaville", "Mangawhai", "Maungaturoto"]),
        // Auckland
        auckland,
        // Waikato
        Council(id: "hamilton-city-council", name: "Hamilton City Council", region: .waikato, anniversary: .auckland,
                website: "https://hamilton.govt.nz/fight-the-landfill/",
                collectionDay: "https://hamilton.govt.nz/fight-the-landfill/kerbside-collection",
                services: [.rubbish, .recycling, .glass, .foodScraps],
                terms: ["Hamilton", "Hamilton City", "Kirikiriroa"], phone: "07 838 6699"),
        Council(id: "waikato-district-council", name: "Waikato District Council", region: .waikato, anniversary: .auckland,
                website: "https://www.waikatodistrict.govt.nz/services-facilities/rubbish-and-recycling",
                services: [.rubbish, .recycling, .glass],
                terms: ["Waikato District", "Huntly", "Ngaruawahia", "Ngāruawāhia", "Raglan", "Te Kauwhata", "Pokeno", "Pōkeno", "Tuakau"]),
        Council(id: "waipa-district-council", name: "Waipā District Council", region: .waikato, anniversary: .auckland,
                website: "https://www.waipadc.govt.nz/our-services/rubbish-and-recycling",
                collectionDay: "https://www.waipadc.govt.nz/our-services/rubbish-and-recycling/recycling/collection-day-finder",
                services: [.rubbish, .recycling],
                terms: ["Waipa", "Waipā", "Waipa District", "Cambridge", "Te Awamutu", "Kihikihi", "Pirongia"]),
        Council(id: "matamata-piako-district-council", name: "Matamata-Piako District Council", region: .waikato, anniversary: .auckland,
                website: "https://www.mpdc.govt.nz/rubbish-and-recycling",
                services: [.rubbish, .recycling, .glass, .foodScraps],
                terms: ["Matamata-Piako", "Matamata", "Morrinsville", "Te Aroha"]),
        Council(id: "hauraki-district-council", name: "Hauraki District Council", region: .waikato, anniversary: .auckland,
                website: "https://www.hauraki-dc.govt.nz/rubbish-recycling",
                collectionDay: "https://www.hauraki-dc.govt.nz/rubbish-recycling/changes-rubbish-recycling-service/collection-days",
                services: [.rubbish, .recycling, .foodScraps],
                terms: ["Hauraki District", "Paeroa", "Waihi", "Ngatea"]),
        Council(id: "thames-coromandel-district-council", name: "Thames-Coromandel District Council", region: .waikato, anniversary: .auckland,
                website: "https://www.tcdc.govt.nz/Our-Services/Rubbish-and-Recycling",
                collectionDay: "https://www.tcdc.govt.nz/Our-Services/Rubbish-and-Recycling/Kerbside-rubbish-and-recycling-services/Your-collection-days",
                services: [.rubbish, .recycling, .glass, .foodScraps],
                terms: ["Thames-Coromandel", "Thames", "Whitianga", "Coromandel", "Whangamata", "Whangamatā", "Tairua", "Pauanui"]),
        Council(id: "otorohanga-district-council", name: "Ōtorohanga District Council", region: .waikato, anniversary: .auckland,
                website: "https://www.otodc.govt.nz/council-services/rubbish-and-recycling",
                collectionDay: "https://www.otodc.govt.nz/council-services/rubbish-and-recycling/kerbside-collection-and-centres",
                services: [.rubbish, .recycling, .glass],
                terms: ["Otorohanga", "Ōtorohanga", "Kawhia"]),
        Council(id: "waitomo-district-council", name: "Waitomo District Council", region: .waikato, anniversary: .auckland,
                website: "https://www.waitomo.govt.nz/our-services/solid-waste-management",
                collectionDay: "https://www.waitomo.govt.nz/our-services/solid-waste-management/kerbside-collection-service",
                services: [.rubbish, .recycling, .glass],
                terms: ["Waitomo", "Waitomo District", "Te Kuiti", "Te Kūiti", "Piopio"]),
        Council(id: "south-waikato-district-council", name: "South Waikato District Council", region: .waikato, anniversary: .auckland,
                website: "https://www.southwaikato.govt.nz/our-services/rubbish-and-recycling",
                collectionDay: "https://www.southwaikato.govt.nz/our-services/rubbish-and-recycling/recycling-calendar",
                services: [.rubbish, .recycling],
                terms: ["South Waikato", "Tokoroa", "Putaruru", "Putāruru", "Tirau", "Tīrau"]),
        Council(id: "taupo-district-council", name: "Taupō District Council", region: .waikato, anniversary: .auckland,
                website: "https://www.taupodc.govt.nz/property-and-rates/rubbish-and-recycling",
                collectionDay: "https://www.taupodc.govt.nz/property-and-rates/rubbish-and-recycling/kerbside-recycling",
                services: [.rubbish, .recycling],
                terms: ["Taupo", "Taupō", "Taupo District", "Turangi", "Tūrangi", "Mangakino"]),
        // Bay of Plenty
        Council(id: "tauranga-city-council", name: "Tauranga City Council", region: .bayOfPlenty, anniversary: .auckland,
                website: "https://www.tauranga.govt.nz/services/rubbish-and-recycling",
                collectionDay: "https://www.tauranga.govt.nz/services/rubbish-and-recycling/kerbside-collections/when-to-put-your-bins-out",
                services: [.rubbish, .recycling, .glass, .foodScraps, .gardenWaste],
                terms: ["Tauranga", "Tauranga City", "Mount Maunganui", "Papamoa", "Pāpāmoa"], phone: "07 577 7000"),
        Council(id: "western-bay-of-plenty-district-council", name: "Western Bay of Plenty District Council", region: .bayOfPlenty, anniversary: .auckland,
                website: "https://www.westernbay.govt.nz/property-rates-and-building/rubbish-and-recycling",
                collectionDay: "https://kerbsidecollective.co.nz/collection-day/",
                services: [.rubbish, .recycling, .glass, .foodScraps],
                terms: ["Western Bay of Plenty", "Te Puke", "Katikati", "Waihi Beach", "Omokoroa", "Ōmokoroa"]),
        Council(id: "rotorua-lakes-council", name: "Rotorua Lakes Council", region: .bayOfPlenty, anniversary: .auckland,
                website: "https://www.rotorualakescouncil.nz/property-building-bins/rubbish-and-recycling",
                collectionDay: "https://www.rotorualakescouncil.nz/property-building-bins/rubbish-and-recycling/bins",
                services: [.rubbish, .recycling, .glass],
                terms: ["Rotorua", "Rotorua Lakes", "Rotorua District", "Ngongotaha", "Ngongotahā"]),
        Council(id: "whakatane-district-council", name: "Whakatāne District Council", region: .bayOfPlenty, anniversary: .auckland,
                website: "https://www.whakatane.govt.nz/services/rubbish-and-recycling",
                services: [.rubbish, .recycling, .glass],
                terms: ["Whakatane", "Whakatāne", "Whakatane District", "Ohope", "Ōhope", "Edgecumbe", "Murupara"]),
        Council(id: "kawerau-district-council", name: "Kawerau District Council", region: .bayOfPlenty, anniversary: .auckland,
                website: "https://www.kaweraudc.govt.nz/services/rubbish-and-recycling",
                services: [.rubbish, .recycling],
                terms: ["Kawerau"]),
        Council(id: "opotiki-district-council", name: "Ōpōtiki District Council", region: .bayOfPlenty, anniversary: .auckland,
                website: "https://www.odc.govt.nz/our-services/rubbish-and-recycling",
                services: [.rubbish, .recycling],
                terms: ["Opotiki", "Ōpōtiki"]),
        // Gisborne
        Council(id: "gisborne-district-council", name: "Gisborne District Council", region: .gisborne, anniversary: .auckland,
                website: "https://www.gdc.govt.nz/services/recycling-and-rubbish",
                collectionDay: "https://www.gdc.govt.nz/services/recycling-and-rubbish/collection-days",
                services: [.rubbish, .recycling],
                terms: ["Gisborne", "Gisborne District", "Tairawhiti", "Tairāwhiti", "Ruatoria", "Tolaga Bay"]),
        // Hawke's Bay
        Council(id: "napier-city-council", name: "Napier City Council", region: .hawkesBay, anniversary: .hawkesBay,
                website: "https://www.napier.govt.nz/services/rubbish-and-recycling/",
                services: [.rubbish, .recycling, .glass],
                terms: ["Napier", "Napier City", "Taradale", "Ahuriri"]),
        Council(id: "hastings-district-council", name: "Hastings District Council", region: .hawkesBay, anniversary: .hawkesBay,
                website: "https://www.hastingsdc.govt.nz/services/rubbish-and-recycling/",
                services: [.rubbish, .recycling, .glass],
                terms: ["Hastings", "Hastings District", "Havelock North", "Flaxmere", "Clive"]),
        Council(id: "central-hawkes-bay-district-council", name: "Central Hawke's Bay District Council", region: .hawkesBay, anniversary: .hawkesBay,
                website: "https://www.chbdc.govt.nz/services/rubbish-and-recycling/",
                services: [.rubbish, .recycling],
                terms: ["Central Hawke's Bay", "Waipukurau", "Waipawa"]),
        Council(id: "wairoa-district-council", name: "Wairoa District Council", region: .hawkesBay, anniversary: .hawkesBay,
                website: "https://www.wairoadc.govt.nz/services/rubbish-and-recycling/",
                services: [.rubbish, .recycling],
                terms: ["Wairoa", "Wairoa District"]),
        // Taranaki
        Council(id: "new-plymouth-district-council", name: "New Plymouth District Council", region: .taranaki, anniversary: .taranaki,
                website: "https://www.npdc.govt.nz/zero-waste/recycling-and-rubbish-collection/",
                collectionDay: "https://www.npdc.govt.nz/zero-waste/recycling-and-rubbish-collection/your-bin-collection-schedule/",
                services: [.rubbish, .recycling, .glass, .foodScraps],
                terms: ["New Plymouth", "New Plymouth District", "Waitara", "Inglewood", "Oakura", "Ōakura", "Bell Block"]),
        Council(id: "stratford-district-council", name: "Stratford District Council", region: .taranaki, anniversary: .taranaki,
                website: "https://www.stratford.govt.nz/our-services/rubbish-and-recycling",
                collectionDay: "https://www.stratford.govt.nz/our-services/rubbish-and-recycling/kerbside-collections",
                services: [.rubbish, .recycling, .glass],
                terms: ["Stratford", "Stratford District"]),
        Council(id: "south-taranaki-district-council", name: "South Taranaki District Council", region: .taranaki, anniversary: .taranaki,
                website: "https://www.southtaranaki.com/our-services/rubbish-and-recycling",
                collectionDay: "https://www.southtaranaki.com/our-services/rubbish-and-recycling/2-find-out-when-your-bins-are-being-collected",
                services: [.rubbish, .recycling, .glass, .foodScraps],
                terms: ["South Taranaki", "Hawera", "Hāwera", "Eltham", "Opunake", "Ōpunake", "Patea", "Pātea", "Manaia"]),
        // Manawatū-Whanganui
        Council(id: "palmerston-north-city-council", name: "Palmerston North City Council", region: .manawatuWhanganui, anniversary: .wellington,
                website: "https://www.pncc.govt.nz/Services/Rubbish-and-recycling",
                services: [.rubbish, .recycling, .glass],
                terms: ["Palmerston North", "Palmerston North City", "Ashhurst"]),
        Council(id: "manawatu-district-council", name: "Manawatū District Council", region: .manawatuWhanganui, anniversary: .wellington,
                website: "https://www.mdc.govt.nz/services/rubbish-recycling-and-waste",
                collectionDay: "https://www.mdc.govt.nz/services/rubbish-recycling-and-waste/feilding-rubbish-and-recycling/find-your-collection-day",
                services: [.rubbish, .recycling, .glass, .foodScraps],
                terms: ["Manawatu", "Manawatū", "Manawatu District", "Feilding"]),
        Council(id: "whanganui-district-council", name: "Whanganui District Council", region: .manawatuWhanganui, anniversary: .wellington,
                website: "https://www.whanganui.govt.nz/Services/Recycling-and-Rubbish",
                services: [.rubbish, .recycling, .glass],
                terms: ["Whanganui", "Wanganui", "Whanganui District"]),
        Council(id: "rangitikei-district-council", name: "Rangitīkei District Council", region: .manawatuWhanganui, anniversary: .wellington,
                website: "https://www.rangitikei.govt.nz/services/rubbish-recycling",
                collectionDay: "https://www.rangitikei.govt.nz/services/rubbish-recycling/collection-days",
                services: [.rubbish, .recycling],
                terms: ["Rangitikei", "Rangitīkei", "Marton", "Bulls", "Taihape"]),
        Council(id: "ruapehu-district-council", name: "Ruapehu District Council", region: .manawatuWhanganui, anniversary: .wellington,
                website: "https://www.ruapehudc.govt.nz/our-services/rubbish-and-recycling",
                collectionDay: "https://www.ruapehudc.govt.nz/our-services/rubbish-and-recycling/kerbside-collection-days",
                services: [.rubbish, .recycling, .foodScraps],
                terms: ["Ruapehu", "Ruapehu District", "Taumarunui", "Ohakune", "Raetihi"]),
        Council(id: "tararua-district-council", name: "Tararua District Council", region: .manawatuWhanganui, anniversary: .wellington,
                website: "https://www.tararuadc.govt.nz/services/rubbish-and-recycling",
                collectionDay: "https://www.tararuadc.govt.nz/services/rubbish-and-recycling/recycling",
                services: [.rubbish, .recycling, .glass],
                terms: ["Tararua", "Tararua District", "Dannevirke", "Pahiatua", "Woodville", "Eketahuna"]),
        Council(id: "horowhenua-district-council", name: "Horowhenua District Council", region: .manawatuWhanganui, anniversary: .wellington,
                website: "https://www.horowhenua.govt.nz/Services/Home-Property/Rubbish-Recycling",
                services: [.rubbish, .recycling, .glass],
                terms: ["Horowhenua", "Levin", "Foxton", "Shannon"]),
        // Wellington
        Council(id: "wellington-city-council", name: "Wellington City Council", region: .wellington, anniversary: .wellington,
                website: "https://wellington.govt.nz/rubbish-recycling-and-waste",
                collectionDay: "https://wellington.govt.nz/rubbish-recycling-and-waste/when-to-put-out-your-rubbish-and-recycling",
                services: [.rubbish, .recycling, .glass],
                terms: ["Wellington", "Wellington City", "Poneke", "Pōneke"], phone: "04 499 4444"),
        Council(id: "hutt-city-council", name: "Hutt City Council", region: .wellington, anniversary: .wellington,
                website: "https://www.huttcity.govt.nz/services/rubbish-and-recycling",
                collectionDay: "https://www.huttcity.govt.nz/services/rubbish-and-recycling/find-my-collection-day2",
                services: [.rubbish, .recycling, .glass, .gardenWaste],
                terms: ["Lower Hutt", "Hutt City", "Wainuiomata", "Petone", "Eastbourne"]),
        Council(id: "upper-hutt-city-council", name: "Upper Hutt City Council", region: .wellington, anniversary: .wellington,
                website: "https://www.upperhutt.govt.nz/services/Waste-and-recycling",
                collectionDay: "https://www.upperhutt.govt.nz/services/Waste-and-recycling/Rubbish",
                services: [.rubbish, .recycling],
                terms: ["Upper Hutt", "Upper Hutt City"]),
        Council(id: "porirua-city-council", name: "Porirua City Council", region: .wellington, anniversary: .wellington,
                website: "https://poriruacity.govt.nz/services/rubbish-and-recycling/",
                services: [.rubbish, .recycling, .glass],
                terms: ["Porirua", "Porirua City", "Whitby", "Plimmerton"]),
        Council(id: "kapiti-coast-district-council", name: "Kāpiti Coast District Council", region: .wellington, anniversary: .wellington,
                website: "https://www.kapiticoast.govt.nz/services/rubbish-and-recycling/",
                services: [.rubbish, .recycling, .glass],
                terms: ["Kapiti", "Kāpiti", "Kapiti Coast", "Kāpiti Coast", "Paraparaumu", "Waikanae", "Otaki", "Ōtaki", "Paekakariki", "Paekākāriki"]),
        Council(id: "masterton-district-council", name: "Masterton District Council", region: .wellington, anniversary: .wellington,
                website: "https://www.mstn.govt.nz/roads-water-and-rubbish/rubbish-recycling-and-waste",
                collectionDay: "https://www.mstn.govt.nz/roads-water-and-rubbish/rubbish-recycling-and-waste/recycling",
                services: [.rubbish, .recycling, .glass],
                terms: ["Masterton", "Masterton District"]),
        Council(id: "carterton-district-council", name: "Carterton District Council", region: .wellington, anniversary: .wellington,
                website: "https://cdc.govt.nz/services/sustainability/recycling/",
                collectionDay: "https://cdc.govt.nz/services/sustainability/recycling/recycling-collections/",
                services: [.rubbish, .recycling, .glass],
                terms: ["Carterton", "Carterton District"]),
        Council(id: "south-wairarapa-district-council", name: "South Wairarapa District Council", region: .wellington, anniversary: .wellington,
                website: "https://swdc.govt.nz/services/rubbish-and-recycling/",
                services: [.rubbish, .recycling, .glass],
                terms: ["South Wairarapa", "Featherston", "Greytown", "Martinborough"]),
        // Tasman, Nelson, Marlborough
        Council(id: "tasman-district-council", name: "Tasman District Council", region: .tasman, anniversary: .nelson,
                website: "https://tasman.govt.nz/my-property/recycling-and-rubbish",
                collectionDay: "https://tasman.govt.nz/my-property/recycling-and-rubbish/kerbside-collections",
                services: [.rubbish, .recycling, .glass],
                terms: ["Tasman", "Tasman District", "Richmond", "Motueka", "Takaka", "Golden Bay", "Mapua", "Māpua"]),
        Council(id: "nelson-city-council", name: "Nelson City Council", region: .nelson, anniversary: .nelson,
                website: "https://nelson.govt.nz/services/recycling-3/kerbside-recycling-service",
                services: [.rubbish, .recycling, .glass],
                terms: ["Nelson", "Nelson City", "Whakatu", "Whakatū", "Stoke"]),
        Council(id: "marlborough-district-council", name: "Marlborough District Council", region: .marlborough, anniversary: .marlborough,
                website: "https://www.marlborough.govt.nz/services/recycling-and-waste/kerbside-collections",
                collectionDay: "https://www.marlborough.govt.nz/services/recycling-and-waste/kerbside-collections/4-what-is-my-collection-day",
                services: [.rubbish, .recycling, .glass],
                terms: ["Marlborough", "Marlborough District", "Blenheim", "Picton", "Renwick"]),
        // West Coast
        Council(id: "buller-district-council", name: "Buller District Council", region: .westCoast, anniversary: .westland,
                website: "https://bullerdc.govt.nz/waste-and-recycling",
                collectionDay: "https://bullerdc.govt.nz/waste-and-recycling/collection-days-and-recycling-calendar/",
                services: [.rubbish, .recycling, .glass],
                terms: ["Buller", "Buller District", "Westport", "Reefton", "Karamea"]),
        Council(id: "grey-district-council", name: "Grey District Council", region: .westCoast, anniversary: .westland,
                website: "https://www.greydc.govt.nz/06your-home/e-refuse-and-recycling",
                collectionDay: "https://www.greydc.govt.nz/06your-home/e-refuse-and-recycling/bkerbside-bin-collection/collection-days",
                services: [.rubbish, .recycling, .glass],
                terms: ["Grey District", "Greymouth", "Runanga"]),
        Council(id: "westland-district-council", name: "Westland District Council", region: .westCoast, anniversary: .westland,
                website: "https://westlanddc.govt.nz/waste-and-recycling/",
                collectionDay: "https://westlanddc.govt.nz/waste-and-recycling/collection-days/",
                services: [.rubbish, .recycling, .glass],
                terms: ["Westland", "Westland District", "Hokitika", "Franz Josef", "Fox Glacier"]),
        // Canterbury
        Council(id: "christchurch-city-council", name: "Christchurch City Council", region: .canterbury, anniversary: .canterbury,
                website: "https://ccc.govt.nz/services/rubbish-and-recycling",
                collectionDay: "https://www.ccc.govt.nz/collection/",
                services: [.rubbish, .recycling, .organics],
                terms: ["Christchurch", "Christchurch City", "Otautahi", "Ōtautahi", "Banks Peninsula", "Akaroa", "Lyttelton"], phone: "03 941 8999"),
        Council(id: "selwyn-district-council", name: "Selwyn District Council", region: .canterbury, anniversary: .canterbury,
                website: "https://www.selwyn.govt.nz/services/rubbish-recycling-And-organics",
                collectionDay: "https://www.selwyn.govt.nz/services/rubbish-recycling-And-organics/kerbside-collections",
                services: [.rubbish, .recycling, .organics],
                terms: ["Selwyn", "Selwyn District", "Rolleston", "Lincoln", "Darfield", "Leeston", "Prebbleton"]),
        Council(id: "waimakariri-district-council", name: "Waimakariri District Council", region: .canterbury, anniversary: .canterbury,
                website: "https://www.waimakariri.govt.nz/services/rubbish,-recycling-and-organics",
                collectionDay: "https://www.waimakariri.govt.nz/services/rubbish,-recycling-and-organics/kerbside-collections",
                services: [.rubbish, .recycling, .organics],
                terms: ["Waimakariri", "Waimakariri District", "Rangiora", "Kaiapoi", "Woodend", "Oxford", "Pegasus"]),
        Council(id: "hurunui-district-council", name: "Hurunui District Council", region: .canterbury, anniversary: .canterbury,
                website: "https://www.hurunui.govt.nz/property-rates/rubbish-recycling",
                collectionDay: "https://www.hurunui.govt.nz/property-rates/rubbish-recycling/collections-rubbish",
                services: [.rubbish, .recycling],
                terms: ["Hurunui", "Hurunui District", "Amberley", "Hanmer Springs", "Culverden", "Cheviot"]),
        Council(id: "kaikoura-district-council", name: "Kaikōura District Council", region: .canterbury, anniversary: .canterbury,
                website: "https://www.kaikoura.govt.nz/our-services/recycling-and-rubbish/",
                services: [.rubbish, .recycling],
                terms: ["Kaikoura", "Kaikōura", "Kaikoura District"]),
        Council(id: "ashburton-district-council", name: "Ashburton District Council", region: .canterbury, anniversary: .canterbury,
                website: "https://www.ashburtondc.govt.nz/services/rubbish-and-recycling",
                collectionDay: "https://www.ashburtondc.govt.nz/services/rubbish-and-recycling/bin-it-right",
                services: [.rubbish, .recycling, .glass],
                terms: ["Ashburton", "Ashburton District", "Methven", "Rakaia"]),
        Council(id: "timaru-district-council", name: "Timaru District Council", region: .canterbury, anniversary: .southCanterbury,
                website: "https://www.timaru.govt.nz/services/environment/waste-minimisation",
                collectionDay: "https://www.timaru.govt.nz/services/environment/waste-minimisation/collection-days",
                services: [.rubbish, .recycling, .glass, .organics],
                terms: ["Timaru", "Timaru District", "Geraldine", "Temuka", "Pleasant Point"]),
        Council(id: "mackenzie-district-council", name: "Mackenzie District Council", region: .canterbury, anniversary: .southCanterbury,
                website: "https://www.mackenzie.govt.nz/services/rubbish-and-recycling",
                collectionDay: "https://www.mackenzie.govt.nz/services/rubbish-and-recycling/bin-collections",
                services: [.rubbish, .recycling, .glass, .organics],
                terms: ["Mackenzie", "Mackenzie District", "Fairlie", "Twizel", "Lake Tekapo", "Tekapo"]),
        Council(id: "waimate-district-council", name: "Waimate District Council", region: .canterbury, anniversary: .southCanterbury,
                website: "https://www.waimatedc.govt.nz/services/rubbish-and-recycling/rubbish-and-recycling",
                collectionDay: "https://www.waimatedc.govt.nz/services/rubbish-and-recycling/digital-resources",
                services: [.rubbish, .recycling, .glass, .organics],
                terms: ["Waimate", "Waimate District"]),
        // Otago
        Council(id: "dunedin-city-council", name: "Dunedin City Council", region: .otago, anniversary: .otago,
                website: "https://www.dunedin.govt.nz/services/rubbish-and-recycling",
                collectionDay: "https://www.dunedin.govt.nz/do-it-online/search/collection-days",
                services: [.rubbish, .recycling, .glass, .organics],
                terms: ["Dunedin", "Dunedin City", "Otepoti", "Ōtepoti", "Mosgiel", "Port Chalmers"], phone: "03 477 4000"),
        Council(id: "queenstown-lakes-district-council", name: "Queenstown Lakes District Council", region: .otago, anniversary: .otago,
                website: "https://www.qldc.govt.nz/services/rubbish-recycling",
                services: [.rubbish, .recycling, .glass],
                terms: ["Queenstown", "Queenstown-Lakes", "Queenstown Lakes", "Queenstown-Lakes District", "Wanaka", "Wānaka", "Arrowtown", "Glenorchy"]),
        Council(id: "central-otago-district-council", name: "Central Otago District Council", region: .otago, anniversary: .otago,
                website: "https://www.codc.govt.nz/services/recycling-and-rubbish",
                collectionDay: "https://www.codc.govt.nz/services/recycling-and-rubbish/01-kerbside-collection-areas-calendars-and-bin-app",
                services: [.rubbish, .recycling, .glass, .organics],
                terms: ["Central Otago", "Central Otago District", "Alexandra", "Cromwell", "Clyde", "Roxburgh", "Ranfurly"]),
        Council(id: "clutha-district-council", name: "Clutha District Council", region: .otago, anniversary: .otago,
                website: "https://www.cluthadc.govt.nz/property-rates-and-building/rubbish-recycling-and-waste-minimisation",
                collectionDay: "https://www.cluthadc.govt.nz/property-rates-and-building/rubbish-recycling-and-waste-minimisation/kerbside-collection",
                services: [.rubbish, .recycling],
                terms: ["Clutha", "Clutha District", "Balclutha", "Milton", "Lawrence"]),
        Council(id: "waitaki-district-council", name: "Waitaki District Council", region: .otago, anniversary: .otago,
                website: "https://www.waitaki.govt.nz/Services/Rubbish-Recycling-Waste-Minimisation",
                services: [.rubbish, .recycling],
                terms: ["Waitaki", "Waitaki District", "Oamaru", "Ōamaru", "Kurow", "Palmerston"]),
        // Southland
        Council(id: "invercargill-city-council", name: "Invercargill City Council", region: .southland, anniversary: .southland,
                website: "https://www.icc.govt.nz/services/rubbish-recycling",
                services: [.rubbish, .recycling],
                terms: ["Invercargill", "Invercargill City", "Waihopai", "Bluff"]),
        Council(id: "southland-district-council", name: "Southland District Council", region: .southland, anniversary: .southland,
                website: "https://www.southlanddc.govt.nz/home-and-property/waste-and-recycling/",
                collectionDay: "https://www.southlanddc.govt.nz/home-and-property/waste-and-recycling/wheelie-bin/",
                services: [.rubbish, .recycling],
                terms: ["Southland District", "Te Anau", "Winton", "Riverton", "Lumsden", "Stewart Island", "Rakiura"]),
        Council(id: "gore-district-council", name: "Gore District Council", region: .southland, anniversary: .southland,
                website: "https://www.goredc.govt.nz/services/waste-minimisation-collection",
                collectionDay: "https://www.goredc.govt.nz/services/waste-minimisation-collection/rubbish-collection-transfer-station",
                services: [.rubbish, .recycling, .glass],
                terms: ["Gore", "Gore District", "Mataura"]),
        // Chatham Islands
        Council(id: "chatham-islands-council", name: "Chatham Islands Council", region: .chathamIslands, anniversary: .chathamIslands,
                website: "https://www.cic.govt.nz/",
                services: [.rubbish, .recycling],
                terms: ["Chatham Islands", "Chatham Island", "Pitt Island", "Rekohu", "Rēkohu", "Wharekauri"],
                timeZoneIdentifier: "Pacific/Chatham")
    ]

    private static let byID: [String: Council] = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    static func council(id: String?) -> Council? {
        id.flatMap { byID[$0] }
    }

    /// Councils grouped by region, in the regions' north-to-south order, each group alphabetical.
    static var grouped: [(region: Region, councils: [Council])] {
        Region.allCases.compactMap { region in
            let members = all.filter { $0.region == region }.sorted { $0.name.folded < $1.name.folded }
            return members.isEmpty ? nil : (region, members)
        }
    }

    /// Case- and macron-insensitive substring search over names, regions and localities.
    static func search(_ query: String) -> [Council] {
        let needle = query.folded.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return all }
        return all.filter { council in
            council.name.folded.contains(needle) || council.region.displayName.folded.contains(needle)
                || council.matchTerms.contains { $0.folded.contains(needle) }
        }
    }

    /// The council an Apple placemark most likely belongs to, or nil when the fields are ambiguous.
    /// Localities and districts are matched exactly; a region decides only when it has one council.
    static func suggestion(locality: String?, subAdministrativeArea: String?, administrativeArea: String?) -> Council? {
        let candidates = [subAdministrativeArea, locality].compactMap { $0?.folded }.filter { !$0.isEmpty }
        for candidate in candidates {
            if let match = all.first(where: { $0.matchTerms.contains { $0.folded == candidate } }) { return match }
        }
        guard let area = administrativeArea?.folded, !area.isEmpty else { return nil }
        if let region = Region.allCases.first(where: { $0.displayName.folded == area || $0.rawValue.folded == area }) {
            let members = all.filter { $0.region == region }
            if members.count == 1 { return members[0] }
        }
        return all.first { $0.matchTerms.contains { $0.folded == area } }
    }
}

extension String {
    /// Lowercased with diacritics removed, so "Whangārei" and "whangarei" compare equal.
    var folded: String { folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil).lowercased() }
}
