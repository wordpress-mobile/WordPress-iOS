import XCTest
@testable import WordPress

class BlogDetailsSectionIndexTests: XCTestCase {
    func testFindingExistingSectionIndex() {
        let blogDetailsViewController = BlogDetailsViewController()
        let sections = [
            BlogDetailsSection(title: nil, andRows: [], category: .general),
            BlogDetailsSection(title: nil, andRows: [], category: .domainCredit)
        ]
        let sectionIndex = blogDetailsViewController.findSectionIndex(sections: sections, category: .general)
        XCTAssertEqual(sectionIndex, 0)
    }

    func testFindingNonExistingSectionIndex() {
        let blogDetailsViewController = BlogDetailsViewController()
        let sections = [
            BlogDetailsSection(title: nil, andRows: [], category: .general),
            BlogDetailsSection(title: nil, andRows: [], category: .domainCredit)
        ]
        let sectionIndex = blogDetailsViewController.findSectionIndex(sections: sections, category: .external)
        XCTAssertEqual(sectionIndex, NSNotFound)
    }

    func testFindingSectionIndexFromEmptySections() {
        let blogDetailsViewController = BlogDetailsViewController()
        let sectionIndex = blogDetailsViewController.findSectionIndex(sections: [], category: .external)
        XCTAssertEqual(sectionIndex, NSNotFound)
    }
}
