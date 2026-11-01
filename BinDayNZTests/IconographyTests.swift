import XCTest
@testable import BinDayNZ

final class IconographyTests: XCTestCase {
    func testBinTypeSymbolsUseOutlineVariants() {
        for bin in BinType.allCases {
            XCTAssertFalse(bin.systemImage.hasSuffix(".fill"), "\(bin) should use an outline symbol")
        }
    }
}
