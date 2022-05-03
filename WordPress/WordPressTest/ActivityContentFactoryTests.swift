import XCTest
@testable import WordPress

final class ActivityContentFactoryTests: XCTestCase {
    private let contextManager = TestContextManager()

    func testActivityContentFactoryReturnsExpectedImplementationOfFormattableContent() throws {
        let subject = ActivityContentFactory.content(from: [try mockBlock()], actionsParser: ActivityActionsParser()).first as? FormattableTextContent

        XCTAssertNotNil(subject)
    }

    private func mockBlock() throws -> [String: AnyObject] {
        return try getDictionaryFromFile(named: "activity-log-activity-content.json")
    }

    private func getDictionaryFromFile(named fileName: String) throws -> [String: AnyObject] {
        return try JSONObject.loadFile(named: fileName)
    }
}
