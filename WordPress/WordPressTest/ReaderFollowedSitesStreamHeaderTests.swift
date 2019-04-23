import XCTest
@testable import WordPress

final class ReaderFollowedSitesStreamHeaderTests: XCTestCase {
    private var subject: ReaderFollowedSitesStreamHeader?

    private struct TestConstants {
        static let label = NSLocalizedString("Manage", comment: "Manage")
        static let hint = NSLocalizedString("Tapping lets you manage the sites you follow.", comment: "Tapping lets you manage the sites you follow.")
        static let traits = UIAccessibilityTraits.button
    }

    override func setUp() {
        super.setUp()
        subject = Bundle.loadRootViewFromNib(type: ReaderFollowedSitesStreamHeader.self)
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func testSubjectIsAccesibilityElement() {
        XCTAssertTrue(subject?.isAccessibilityElement ?? false, "ReaderFollowedSitesStreamHeader should be an accessibility element")
    }

    func testSubjectLabeMatchesExpectation() {
        XCTAssertEqual(subject?.accessibilityLabel, String(format: "%@",TestConstants.label), "Accessibility label does not return the expected value")
    }

    func testSubjectHintMatchesExpectation() {
        XCTAssertEqual(subject?.accessibilityHint, String(format: "%@",TestConstants.hint), "Accessibility hint does not return the expected value")
    }

    func testSubjectTraitsMatchesExpectation() {
        XCTAssertEqual(subject?.accessibilityTraits, TestConstants.traits, "Accessibility traits do not return the expected value")
    }
}
