import XCTest
@testable import WordPress

final class FormattableNotIconTests: XCTestCase {
    private let contextManager = TestContextManager()

    private var subject: FormattableNoticonRange?

    private struct Constants {
        static let kind = FormattableRangeKind("noticon")
        static let icon = "🦄"
        static let range = NSRange(location: 32, length: 41)
    }

    override func setUp() {
        super.setUp()
        subject = FormattableNoticonRange(value: Constants.icon, range: Constants.range)
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func testKindIsNotMutated() {
        XCTAssertEqual(subject?.kind, Constants.kind)
    }

    func testRangeIsNotMutated() {
        XCTAssertEqual(subject?.range, Constants.range)
    }

    func testNoticonReturnsExpectedValue() {
        XCTAssertEqual(subject?.value, Constants.icon)
    }

    private func mockProperties() -> NotificationContentRange.Properties {
        return NotificationContentRange.Properties(range: Constants.range)
    }
}
