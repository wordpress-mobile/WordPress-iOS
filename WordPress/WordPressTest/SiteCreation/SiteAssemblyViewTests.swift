
import XCTest
@testable import WordPress

class SiteAssemblyViewTests: XCTestCase {

    func testContentView_ViewIsCorrect_WhenStatusIsIdle() {
        // Given
        let contentView = SiteAssemblyContentView()

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
        // Given
        let contentView = SiteAssemblyContentView()

        // When
        contentView.status = .inProgress
        contentView.layoutIfNeeded()
        wait(for: 0.5)

        // Then
        let actualStatusStackViewAlpha = contentView.statusStackView.alpha
        XCTAssertEqual(actualStatusStackViewAlpha, 1, accuracy: 0.01)
    }

    func testContentView_ViewIsCorrect_WhenStatusIsSucceeded() {
        // Given
        let contentView = SiteAssemblyContentView()

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
        // Given
        let contentView = SiteAssemblyContentView()

        // When
        contentView.siteURLString = "https://wordpress.com"
        contentView.siteName = "wordpress.com"

        // Then
        XCTAssertNotNil(contentView.assembledSiteView)
    }

    func testContentView_ButtonContainerView_IsProperlyInstalled() {
        // Given
        let contentView = SiteAssemblyContentView()

        // When
        contentView.buttonContainerView = UIView()

        // Then
        XCTAssertNotNil(contentView.buttonContainerView)
    }
}
