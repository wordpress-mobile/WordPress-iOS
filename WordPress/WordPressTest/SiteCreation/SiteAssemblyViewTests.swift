
import XCTest
@testable import WordPress

class SiteAssemblyViewTests: XCTestCase {

    var contentView: SiteAssemblyContentView!
    var siteCreator: SiteCreator!

    override func setUp() {
        super.setUp()
        siteCreator = SiteCreator()
        contentView = SiteAssemblyContentView(siteCreator: siteCreator)
    }

    func testContentView_ViewIsCorrect_WhenStatusIsIdle() {
        // When
        contentView.status = .idle
        contentView.layoutIfNeeded()
        wait(for: 0.5)

        // Then
        let actualCompletionLabelAlpha = contentView.completionLabel.alpha
        XCTAssertEqual(actualCompletionLabelAlpha, 0, accuracy: 0.01)

        let actualStatusStackViewAlpha = contentView.statusStackView.alpha
        XCTAssertEqual(actualStatusStackViewAlpha, 0, accuracy: 0.01)
    }

    func testContentView_ViewIsCorrect_WhenStatusIsInProgress() {
        // When
        contentView.status = .inProgress
        contentView.layoutIfNeeded()
        wait(for: 0.5)

        // Then
        let actualStatusStackViewAlpha = contentView.statusStackView.alpha
        XCTAssertEqual(actualStatusStackViewAlpha, 1, accuracy: 0.01)
    }

    func testContentView_ViewIsCorrect_WhenStatusIsSucceeded() {
        // When
        contentView.status = .succeeded
        contentView.layoutIfNeeded()
        wait(for: 0.75)

        // Then
        let actualCompletionLabelAlpha = contentView.completionLabel.alpha
        XCTAssertEqual(actualCompletionLabelAlpha, 1, accuracy: 0.01)

        let actualStatusStackViewAlpha = contentView.statusStackView.alpha
        XCTAssertEqual(actualStatusStackViewAlpha, 0, accuracy: 0.01)
    }

    func testContentView_AssembledSiteView_IsProperlyInstalled() {
        // When
        contentView.siteURLString = "https://wordpress.com"
        contentView.siteName = "wordpress.com"

        // Then
        XCTAssertNotNil(contentView.assembledSiteView)
    }

    func testContentView_ButtonContainerView_IsProperlyInstalled() {
        // When
        contentView.buttonContainerView = UIView()

        // Then
        XCTAssertNotNil(contentView.buttonContainerView)
    }
}
