import Foundation
@testable import WordPress


// MARK: - DictionaryHelpersTests
//
class DictionaryHelpersTests: XCTestCase {
    func testValueAsStringReturnsTheExpectedStringWhenTheValueIsEffectivelyAsString() {
        let dictionary = [
            "key": "value!"
        ]

        let retrieved = dictionary.valueAsString(forKey: "key")
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved, "value!")
    }

    func testValueAsStringReturnsTheExpectedStringWhenTheValueIsNumeric() {
        let dictionary = [
            "key": 1234
        ]

        let retrieved = dictionary.valueAsString(forKey: "key")
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved, "1234")
    }
}
