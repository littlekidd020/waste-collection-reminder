import XCTest
@testable import BinDayNZ

final class CouncilDirectoryTests: XCTestCase {
    func testEveryTerritorialAuthorityIsListedOnceWithUsableLinks() {
        let all = CouncilDirectory.all
        XCTAssertEqual(all.count, 67, "66 territorial authorities plus the Chatham Islands")
        XCTAssertEqual(Set(all.map(\.id)).count, all.count)
        XCTAssertEqual(Set(all.map(\.name)).count, all.count)
        for council in all {
            XCTAssertEqual(council.website.scheme, "https", council.id)
            XCTAssertEqual(council.collectionDayURL.scheme, "https", council.id)
            XCTAssertEqual(council.holidayPolicy.sourceURL.scheme, "https", council.id)
            XCTAssertTrue(council.services.contains(.rubbish) && council.services.contains(.recycling), council.id)
            XCTAssertFalse(council.matchTerms.isEmpty, council.id)
            XCTAssertNotNil(TimeZone(identifier: council.timeZoneIdentifier), council.id)
            if let phone = council.phone {
                XCTAssertEqual(council.phoneURL?.absoluteString, "tel:" + phone.filter(\.isNumber))
            }
        }
        for region in Region.allCases {
            XCTAssertFalse(all.filter { $0.region == region }.isEmpty, "\(region) has no council")
        }
        XCTAssertEqual(CouncilDirectory.grouped.map(\.region), Region.allCases)
        XCTAssertEqual(CouncilDirectory.grouped.flatMap(\.councils).count, all.count)
    }

    func testMatchTermsNeverPointAtTwoCouncils() {
        var seen: [String: String] = [:]
        for council in CouncilDirectory.all {
            for term in council.matchTerms {
                let key = term.folded // macron and plain spellings of one town fold together on purpose
                XCTAssertTrue(seen[key] == nil || seen[key] == council.id, "\(term) is claimed by \(seen[key] ?? "") and \(council.id)")
                seen[key] = council.id
            }
        }
    }

    func testSavedProfilesFromEarlierVersionsStillResolveToAuckland() {
        XCTAssertEqual(DataService.aucklandCouncilID, "auckland-council")
        XCTAssertEqual(CouncilDirectory.council(id: "auckland-council"), CouncilDirectory.auckland)
        XCTAssertNil(CouncilDirectory.council(id: nil))
        XCTAssertNil(CouncilDirectory.council(id: "akl-dynamic-1-even"))
        let profile = UserProfile()
        profile.councilId = "auckland-council"
        XCTAssertEqual(DataService.shared.council(for: profile), CouncilDirectory.auckland)
        XCTAssertTrue(CouncilDirectory.auckland.holidayPolicy.appliesAutomatically)
        XCTAssertEqual(CouncilDirectory.auckland.services, [.rubbish, .recycling, .foodScraps, .inorganic])
        XCTAssertTrue(CouncilDirectory.all.filter { $0.holidayPolicy.appliesAutomatically }.allSatisfy { $0 == CouncilDirectory.auckland },
                      "Only a verified published rule is applied automatically")
        XCTAssertTrue(CouncilDirectory.all.filter { $0.services.contains(.inorganic) }.allSatisfy { $0 == CouncilDirectory.auckland })
    }

    func testPlacemarkSuggestionsMatchLocalitiesExactlyAndRegionsOnlyWhenUnambiguous() {
        XCTAssertEqual(CouncilDirectory.suggestion(locality: "Hamilton", subAdministrativeArea: nil, administrativeArea: "Waikato")?.id, "hamilton-city-council")
        XCTAssertEqual(CouncilDirectory.suggestion(locality: "Cambridge", subAdministrativeArea: "Waipa District", administrativeArea: "Waikato")?.id, "waipa-district-council")
        XCTAssertEqual(CouncilDirectory.suggestion(locality: "Whangarei", subAdministrativeArea: nil, administrativeArea: "Northland")?.id, "whangarei-district-council")
        XCTAssertEqual(CouncilDirectory.suggestion(locality: "Whangārei", subAdministrativeArea: nil, administrativeArea: nil)?.id, "whangarei-district-council")
        XCTAssertEqual(CouncilDirectory.suggestion(locality: "Ponsonby", subAdministrativeArea: nil, administrativeArea: "Auckland")?.id, "auckland-council")
        XCTAssertEqual(CouncilDirectory.suggestion(locality: "Lower Hutt", subAdministrativeArea: nil, administrativeArea: "Wellington")?.id, "hutt-city-council")
        XCTAssertEqual(CouncilDirectory.suggestion(locality: "Palmerston", subAdministrativeArea: nil, administrativeArea: "Otago")?.id, "waitaki-district-council")
        XCTAssertEqual(CouncilDirectory.suggestion(locality: "Palmerston North", subAdministrativeArea: nil, administrativeArea: nil)?.id, "palmerston-north-city-council")
        XCTAssertEqual(CouncilDirectory.suggestion(locality: nil, subAdministrativeArea: nil, administrativeArea: "Gisborne")?.id, "gisborne-district-council")
        XCTAssertNil(CouncilDirectory.suggestion(locality: "Riccarton", subAdministrativeArea: nil, administrativeArea: "Canterbury"), "Canterbury has nine councils")
        XCTAssertNil(CouncilDirectory.suggestion(locality: nil, subAdministrativeArea: nil, administrativeArea: nil))
        XCTAssertNil(CouncilDirectory.suggestion(locality: "Sydney", subAdministrativeArea: nil, administrativeArea: "New South Wales"))
    }

    func testSearchIgnoresCaseAndMacronsAndFindsTowns() {
        let whang = CouncilDirectory.search("whang").map(\.id)
        XCTAssertEqual(whang.first, "whangarei-district-council")
        XCTAssertTrue(whang.contains("whanganui-district-council"))
        XCTAssertTrue(whang.contains("thames-coromandel-district-council"), "Whangamatā is a Thames-Coromandel town")
        XCTAssertEqual(CouncilDirectory.search("ōtaki").map(\.id), ["kapiti-coast-district-council"])
        XCTAssertEqual(CouncilDirectory.search("Mosgiel").map(\.id), ["dunedin-city-council"])
        XCTAssertEqual(CouncilDirectory.search("  ").count, CouncilDirectory.all.count)
        XCTAssertTrue(CouncilDirectory.search("zzzz").isEmpty)
    }

    func testEditorOffersTheCouncilsBinsFirstAndEveryOtherRegularBin() throws {
        let dunedin = try XCTUnwrap(CouncilDirectory.council(id: "dunedin-city-council"))
        let bins = ManualScheduleView.editableBins(for: dunedin)
        XCTAssertEqual(bins.offered, [.rubbish, .recycling, .glass, .organics])
        XCTAssertEqual(bins.all, [.rubbish, .recycling, .glass, .organics, .foodScraps, .gardenWaste])
        let auckland = ManualScheduleView.editableBins(for: CouncilDirectory.auckland)
        XCTAssertEqual(auckland.offered, [.rubbish, .recycling, .foodScraps], "Inorganic is booked, never a regular cycle")
        XCTAssertEqual(ManualScheduleView.editableBins(for: nil).offered, [.rubbish, .recycling, .foodScraps])
        XCTAssertFalse(bins.all.contains(.inorganic))
    }

    func testRegionalHolidayDatesFallOnTheirStatutoryWeekdays() {
        let calendar = ScheduleEngine.collectionCalendar
        for holiday in PublicHoliday.season2026_27 {
            let weekday = calendar.component(.weekday, from: holiday.date)
            switch holiday.id {
            case "christmas-2026", "good-friday-2027", "matariki-2027", "hawkes-bay-anniversary-2027", "canterbury-anniversary-2027":
                XCTAssertEqual(weekday, 6, "\(holiday.id) is a Friday")
            case "southland-anniversary-2027":
                XCTAssertEqual(weekday, 3, "Easter Tuesday")
            case "new-year-2027":
                XCTAssertEqual(weekday, 6)
            default:
                XCTAssertEqual(weekday, 2, "\(holiday.id) is observed on a Monday")
            }
        }
        XCTAssertEqual(Set(PublicHoliday.season2026_27.map(\.id)).count, PublicHoliday.season2026_27.count)
        for anniversary in AnniversaryDay.allCases {
            XCTAssertEqual(PublicHoliday.season2026_27.filter { $0.anniversary == anniversary }.count, 1, "\(anniversary) has one date")
        }
    }
}
