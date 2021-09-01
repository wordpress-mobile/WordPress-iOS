import XCTest

@testable import WordPress

final class ShareAppTextActivityItemSourceTests: XCTestCase {

    func test_itemSource_returnsCorrectContentType() {
        let source = ShareAppTextActivityItemSource(message: Expectations.message)
        let placeholder = source.activityViewControllerPlaceholderItem(makeController())

        XCTAssertTrue(placeholder is String)
    }

    func test_itemSource_returnsCorrectSubjectString() {
        let source = ShareAppTextActivityItemSource(message: Expectations.message)
        let subject = source.activityViewController(makeController(), subjectForActivityType: nil)

        XCTAssertEqual(subject, Expectations.subject)
    }

    func test_givenAnyActivityType_returnsCorrectItem() {
        let source = ShareAppTextActivityItemSource(message: Expectations.message)
        let item = source.activityViewController(makeController(), itemForActivityType: nil)

        XCTAssertNotNil(item)
        XCTAssertEqual(item! as! String, Expectations.message)
    }
}

private extension ShareAppTextActivityItemSourceTests {

    func makeController() -> UIActivityViewController {
        return UIActivityViewController(activityItems: [], applicationActivities: nil)
    }

    struct Expectations {
        static let message = "Expected message"
        static let subject = NSLocalizedString("WordPress Apps - Apps for any screen",
                                               comment: "Subject line for when sharing the app with others through mail or any other activity types "
                                                + "that support contains a subject field.")
    }
}
