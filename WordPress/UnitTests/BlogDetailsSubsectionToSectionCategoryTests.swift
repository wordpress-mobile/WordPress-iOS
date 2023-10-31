import XCTest
@testable import WordPress

class BlogDetailsSubsectionToSectionCategoryTests: CoreDataTestCase {
    var blog: Blog!

    override func setUp() {
        blog = BlogBuilder(contextManager.mainContext).build()
    }

    func testEachSubsectionToSectionCategory() {
        let blogDetailsViewController = BlogDetailsViewController()
        XCTAssertEqual(blogDetailsViewController.sectionCategory(subsection: .domainCredit, blog: blog), .domainCredit)
        XCTAssertEqual(blogDetailsViewController.sectionCategory(subsection: .quickStart, blog: blog), .quickStart)
        XCTAssertEqual(blogDetailsViewController.sectionCategory(subsection: .stats, blog: blog), .general)
        XCTAssertEqual(blogDetailsViewController.sectionCategory(subsection: .activity, blog: blog), .jetpack)
        XCTAssertEqual(blogDetailsViewController.sectionCategory(subsection: .pages, blog: blog), .content)
        XCTAssertEqual(blogDetailsViewController.sectionCategory(subsection: .posts, blog: blog), .content)
        XCTAssertEqual(blogDetailsViewController.sectionCategory(subsection: .media, blog: blog), .content)
        XCTAssertEqual(blogDetailsViewController.sectionCategory(subsection: .comments, blog: blog), .content)
        XCTAssertEqual(blogDetailsViewController.sectionCategory(subsection: .themes, blog: blog), .personalize)
        XCTAssertEqual(blogDetailsViewController.sectionCategory(subsection: .customize, blog: blog), .personalize)
        XCTAssertEqual(blogDetailsViewController.sectionCategory(subsection: .sharing, blog: blog), .configure)
        XCTAssertEqual(blogDetailsViewController.sectionCategory(subsection: .people, blog: blog), .configure)
        XCTAssertEqual(blogDetailsViewController.sectionCategory(subsection: .plugins, blog: blog), .configure)
    }

    func testEachSubsectionToSectionCategoryForJetpack() {
        let blogDetailsViewController = BlogDetailsViewController()
        let blog = BlogBuilder(contextManager.mainContext)
            .set(blogOption: "is_wpforteams_site", value: false)
            .withAnAccount()
            .with(isAdmin: true)
            .build()

        XCTAssertEqual(blogDetailsViewController.sectionCategory(subsection: .stats, blog: blog), .jetpack)
    }
}
