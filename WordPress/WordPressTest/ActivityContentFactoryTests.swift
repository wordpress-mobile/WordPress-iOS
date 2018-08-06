import XCTest
@testable import WordPress

final class ActivityContentFactoryTests: XCTestCase {
    private let contextManager = TestContextManager()

    func testActivityContentFactoryReturnsExpectedImplementationOfFormattableContent() {
        let subject = ActivityContentFactory.content(from: [mockBlock()], actionsParser: ActivityActionsParser()).first as? FormattableTextContent

        XCTAssertNotNil(subject)
    }

    private func mockBlock() -> [String: AnyObject] {
        return getDictionaryFromFile(named: "activity-log-activity-content.json")
    }

    private func getDictionaryFromFile(named fileName: String) -> [String: AnyObject] {
        return contextManager.object(withContentOfFile: fileName) as! [String: AnyObject]
    }
}
