import Foundation
import Testing
@testable import WordPressShared

// MARK: - DictionaryHelpersTests
//
struct DictionaryHelpersTests {
    @Test func testValueAsStringReturnsTheExpectedStringWhenTheValueIsEffectivelyAsString() {
        let dictionary = [
            "key": "value!"
        ]

        let retrieved = dictionary.valueAsString(forKey: "key")
        #expect(retrieved != nil)
        #expect(retrieved == "value!")
    }

    @Test func testValueAsStringReturnsTheExpectedStringWhenTheValueIsNumeric() {
        let dictionary = [
            "key": 1234
        ]

        let retrieved = dictionary.valueAsString(forKey: "key")
        #expect(retrieved != nil)
        #expect(retrieved == "1234")
    }
}
