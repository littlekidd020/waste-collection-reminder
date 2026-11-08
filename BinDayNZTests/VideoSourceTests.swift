import XCTest
@testable import BinDayNZ

final class VideoSourceTests: XCTestCase {
    func testRubbishDoesNotShowTheRecyclingVideo() {
        XCTAssertNil(BinType.rubbish.youTubeVideoID)
        XCTAssertNil(BinType.rubbish.videoURL)
    }

    @MainActor
    func testOptionalVideosUsePrivateEmbedsAndASeparateExternalURL() throws {
        XCTAssertEqual(BinType.allCases.filter { $0.youTubeVideoID != nil }, [.recycling, .foodScraps, .inorganic])
        for bin in [BinType.recycling, .foodScraps, .inorganic] {
            let id = try XCTUnwrap(bin.youTubeVideoID)
            XCTAssertEqual(bin.youTubeVideoID(for: CouncilDirectory.auckland), id, "Auckland keeps its videos")
            XCTAssertNil(bin.youTubeVideoID(for: CouncilDirectory.council(id: "wellington-city-council")), "Videos are Auckland Council content")
            let externalURL = try XCTUnwrap(bin.videoURL)
            let request = YouTubePlayerView.request(for: id)
            XCTAssertEqual(request.url?.scheme, "https")
            XCTAssertEqual(request.url?.host, "www.youtube-nocookie.com")
            XCTAssertEqual(request.url?.path, "/embed/\(id)")
            XCTAssertEqual(externalURL.host, "www.youtube.com")
            XCTAssertFalse(request.url!.absoluteString.contains("autoplay=1"))
            XCTAssertEqual(request.value(forHTTPHeaderField: "Referer"), Bundle.main.bundleIdentifier.map { "https://\($0.lowercased())" })
        }
    }

    func testGuidesKeepTheReviewedFoodAndInorganicExceptions() throws {
        let priorLanguage = LanguageManager.shared.currentCode
        LanguageManager.shared.apply("en")
        defer { LanguageManager.shared.apply(priorLanguage) }

        XCTAssertTrue(BinType.foodScraps.acceptedItems.contains("Loose tea leaves and coffee grounds"))
        XCTAssertTrue(BinType.foodScraps.rejectedItems.contains("Tea bags"))
        XCTAssertTrue(BinType.foodScraps.acceptedItems.contains("Certified home-compostable bin liners"))
        XCTAssertTrue(BinType.inorganic.acceptedItems.contains("Timber under two metres, with no exposed nails"))
        XCTAssertTrue(BinType.inorganic.guideNotes.contains { $0.contains("inside your property boundary") })
        XCTAssertTrue(BinType.inorganic.guideNotes.contains { $0.contains("55 kg") })
        let wellington = try XCTUnwrap(CouncilDirectory.council(id: "wellington-city-council"))
        for bin in BinType.allCases {
            XCTAssertEqual(bin.guideSourceURL(for: CouncilDirectory.auckland).scheme, "https")
            XCTAssertTrue(bin.guideSourceURL(for: CouncilDirectory.auckland).host!.hasSuffix(".aucklandcouncil.govt.nz"))
            XCTAssertEqual(bin.guideSourceURL(for: wellington), wellington.website)
            XCTAssertEqual(bin.guideSourceURL(for: nil), bin.aucklandGuideURL)
        }
    }

    func testCouncilsWithAGlassBinKeepGlassOutOfRecycling() throws {
        let priorLanguage = LanguageManager.shared.currentCode
        LanguageManager.shared.apply("en")
        defer { LanguageManager.shared.apply(priorLanguage) }
        let wellington = try XCTUnwrap(CouncilDirectory.council(id: "wellington-city-council"))
        XCTAssertTrue(wellington.services.contains(.glass))
        XCTAssertFalse(BinType.recycling.acceptedItems(for: wellington).contains("Glass bottles and jars"))
        XCTAssertTrue(BinType.recycling.rejectedItems(for: wellington).first!.hasPrefix("Glass bottles and jars"))
        XCTAssertTrue(BinType.recycling.acceptedItems(for: CouncilDirectory.auckland).contains("Glass bottles and jars"))
        XCTAssertEqual(BinType.guideBins(for: CouncilDirectory.auckland), [.rubbish, .recycling, .foodScraps, .inorganic])
        XCTAssertEqual(BinType.guideBins(for: wellington), [.rubbish, .recycling, .glass])
        XCTAssertFalse(BinType.inorganic.guideNotes(for: wellington).isEmpty)
    }
}
