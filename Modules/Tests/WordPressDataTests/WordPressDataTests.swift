import Testing
import XCTest
@testable import WordPressData

final class WordPressDataTests: XCTestCase {

    func testExample() throws {
        XCTAssertEqual(WordPressDataDummy.dummyText, "dummy")
    }
}

@Test("A dummy test just to check the setup")
func dummy() {
    #expect(WordPressDataDummy.dummyText == "dummy")
}
