import XCTest
@testable import WordPressKit

class FeatureFlagSerializationTest: XCTestCase {
    /// The `FeatureFlagList` typealias can't have its `encode` method overridden, so instead we ensure that it's serializing its messages properly.
    func testThatSingleFeatureFlagIsSerializedCorrectly() throws {
        let title = UUID().uuidString
        let value = Bool.random()

        let flags = [FeatureFlag(title: title, value: value)]
        let json = String(bytes: try! JSONEncoder().encode(flags.dictionaryValue), encoding: .utf8)
        XCTAssertEqual("{\"\(title)\":\(value)}", json)
    }
}
