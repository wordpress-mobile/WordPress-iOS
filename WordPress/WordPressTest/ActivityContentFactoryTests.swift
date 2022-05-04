import XCTest
@testable import WordPress

final class ActivityContentFactoryTests: XCTestCase {
    private let contextManager = TestContextManager()

    func testActivityContentFactoryReturnsExpectedImplementationOfFormattableContent() throws {
        let subject = ActivityContentFactory.content(from: [try mockBlock()], actionsParser: ActivityActionsParser()).first as? FormattableTextContent

        XCTAssertNotNil(subject)
    }

    private func mockBlock() throws -> JSONObject {
        return try .loadFile(named: "activity-log-activity-content.json")
    }

}
