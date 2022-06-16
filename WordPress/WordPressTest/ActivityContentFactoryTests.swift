import XCTest
@testable import WordPress

final class ActivityContentFactoryTests: XCTestCase {

    func testActivityContentFactoryReturnsExpectedImplementationOfFormattableContent() throws {
        let subject = ActivityContentFactory.content(from: [try mockBlock()], actionsParser: ActivityActionsParser()).first as? FormattableTextContent
        XCTAssertNotNil(subject)
    }

    private func mockBlock() throws -> JSONObject {
        return try JSONObject(fromFileNamed: "activity-log-activity-content.json")
    }

}
