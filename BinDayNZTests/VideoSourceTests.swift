import XCTest
@testable import BinDayNZ

final class VideoSourceTests: XCTestCase {
    func testRubbishDoesNotShowTheRecyclingVideo() {
        XCTAssertNil(BinType.rubbish.youTubeVideoID)
        XCTAssertNil(BinType.rubbish.videoURL)
    }

    @MainActor
    func testOptionalVideosUsePrivateEmbedsAndASeparateExternalURL() throws {
        for bin in BinType.allCases where bin != .rubbish {
            let id = try XCTUnwrap(bin.youTubeVideoID)
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

    func testGuidesKeepTheReviewedFoodAndInorganicExceptions() {
        let priorLanguage = LanguageManager.shared.currentCode
        LanguageManager.shared.apply("en")
        defer { LanguageManager.shared.apply(priorLanguage) }

        XCTAssertTrue(BinType.foodScraps.acceptedItems.contains("Loose tea leaves and coffee grounds"))
        XCTAssertTrue(BinType.foodScraps.rejectedItems.contains("Tea bags"))
        XCTAssertTrue(BinType.foodScraps.acceptedItems.contains("Certified home-compostable bin liners"))
        XCTAssertTrue(BinType.inorganic.acceptedItems.contains("Timber under two metres, with no exposed nails"))
        XCTAssertTrue(BinType.inorganic.guideNotes.contains { $0.contains("inside your property boundary") })
        XCTAssertTrue(BinType.inorganic.guideNotes.contains { $0.contains("55 kg") })
        for bin in BinType.allCases {
            XCTAssertEqual(bin.guideSourceURL.scheme, "https")
            XCTAssertTrue(bin.guideSourceURL.host!.hasSuffix(".aucklandcouncil.govt.nz"))
        }
    }
}
