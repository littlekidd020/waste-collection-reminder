import XCTest
@testable import BinDayNZ

final class AppLanguageTests: XCTestCase {
    func testDeviceLanguagePicksTheShippedLocalization() {
        XCTAssertEqual(AppLanguage.preferred(from: ["en-NZ"]), .english)
        XCTAssertEqual(AppLanguage.preferred(from: ["mi-NZ", "en-NZ"]), .teReoMaori)
        XCTAssertEqual(AppLanguage.preferred(from: ["zh-Hans-CN", "en"]), .simplifiedChinese)
        XCTAssertEqual(AppLanguage.preferred(from: ["zh-CN"]), .simplifiedChinese)
        XCTAssertEqual(AppLanguage.preferred(from: ["hi-IN"]), .hindi)
        XCTAssertEqual(AppLanguage.preferred(from: ["ko-KR"]), .korean)
    }

    func testFirstMatchingPreferenceWinsOverLaterOnes() {
        XCTAssertEqual(AppLanguage.preferred(from: ["fr-FR", "ko-KR", "en"]), .korean)
    }

    func testUnsupportedDeviceLanguageFallsBackToEnglish() {
        XCTAssertEqual(AppLanguage.preferred(from: ["fr-FR", "de-DE"]), .english)
        XCTAssertEqual(AppLanguage.preferred(from: ["zh-Hant-TW"]), .english)
        XCTAssertEqual(AppLanguage.preferred(from: []), .english)
    }

    func testNewProfileStartsInTheDeviceLanguage() {
        XCTAssertEqual(UserProfile().languageCode, AppLanguage.deviceDefault.rawValue)
    }
}
