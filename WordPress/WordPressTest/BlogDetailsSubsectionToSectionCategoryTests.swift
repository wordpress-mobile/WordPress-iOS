import XCTest
@testable import WordPress

class BlogDetailsSubsectionToSectionCategoryTests: XCTestCase {
    func testEachSubsectionToSectionCategory() {
        let blogDetailsViewController = BlogDetailsViewController()
        XCTAssertEqual(blogDetailsViewController.sectionCategory(subsection: .domainCredit), .domainCredit)
        XCTAssertEqual(blogDetailsViewController.sectionCategory(subsection: .quickStart), .quickStart)
        XCTAssertEqual(blogDetailsViewController.sectionCategory(subsection: .stats), .general)
        XCTAssertEqual(blogDetailsViewController.sectionCategory(subsection: .activity), .general)
        XCTAssertEqual(blogDetailsViewController.sectionCategory(subsection: .pages), .publish)
        XCTAssertEqual(blogDetailsViewController.sectionCategory(subsection: .posts), .publish)
        XCTAssertEqual(blogDetailsViewController.sectionCategory(subsection: .media), .publish)
        XCTAssertEqual(blogDetailsViewController.sectionCategory(subsection: .comments), .publish)
        XCTAssertEqual(blogDetailsViewController.sectionCategory(subsection: .themes), .personalize)
        XCTAssertEqual(blogDetailsViewController.sectionCategory(subsection: .customize), .personalize)
        XCTAssertEqual(blogDetailsViewController.sectionCategory(subsection: .sharing), .configure)
        XCTAssertEqual(blogDetailsViewController.sectionCategory(subsection: .people), .configure)
        XCTAssertEqual(blogDetailsViewController.sectionCategory(subsection: .plugins), .configure)
    }
}
