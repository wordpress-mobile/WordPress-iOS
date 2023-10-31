import XCTest
@testable import WordPress

class ErrorStateViewTests: XCTestCase {

    // MARK: ErrorStateView

    func testErrorStateView_DefaultIsConfiguredCorrectly_ForErrorStateViewType_General() {
        // Given, When
        let config = ErrorStateViewConfiguration.configuration(type: .general)
        let errorStateView = ErrorStateView(with: config)

        // Then
        XCTAssertNotNil(errorStateView.titleLabel)
        XCTAssertNotNil(errorStateView.subtitleLabel)
        XCTAssertNil(errorStateView.retryButton)
        XCTAssertNil(errorStateView.contactSupportLabel)
        XCTAssertNil(errorStateView.dismissalImageView)
    }

    func testErrorStateView_DefaultIsConfiguredCorrectly_ForErrorStateViewType_SiteLoading() {
        // Given, When
        let config = ErrorStateViewConfiguration.configuration(type: .siteLoading)
        let errorStateView = ErrorStateView(with: config)

        // Then
        XCTAssertNotNil(errorStateView.titleLabel)
        XCTAssertNotNil(errorStateView.subtitleLabel)
        XCTAssertNil(errorStateView.retryButton)
        XCTAssertNil(errorStateView.contactSupportLabel)
        XCTAssertNil(errorStateView.dismissalImageView)
    }

    func testErrorStateView_DefaultIsConfiguredCorrectly_ForErrorStateViewType_NetworkUnreachable() {
        // Given, When
        let config = ErrorStateViewConfiguration.configuration(type: .networkUnreachable)
        let errorStateView = ErrorStateView(with: config)

        // Then
        XCTAssertNotNil(errorStateView.titleLabel)
        XCTAssertNil(errorStateView.subtitleLabel)
        XCTAssertNil(errorStateView.retryButton)
        XCTAssertNil(errorStateView.contactSupportLabel)
        XCTAssertNil(errorStateView.dismissalImageView)
    }

    // MARK: ErrorStateViewConfiguration

    func testErrorStateViewConfiguration_IsConfiguredCorrectly_ForErrorStateViewType_General() {
        // Given, When
        let config = ErrorStateViewConfiguration.configuration(type: .general)

        // Then
        let actualTitle = config.title
        let expectedTitle = NSLocalizedString("There was a problem", comment: "No comment (test)")
        XCTAssertEqual(expectedTitle, actualTitle)

        let actualSubtitle = config.subtitle
        let expectedSubtitle = NSLocalizedString("Error communicating with the server, please try again", comment: "No comment (test)")
        XCTAssertEqual(expectedSubtitle, actualSubtitle)

        XCTAssertNil(config.retryActionHandler)
        XCTAssertNil(config.contactSupportActionHandler)
        XCTAssertNil(config.dismissalActionHandler)
    }

    func testErrorStateViewConfiguration_IsConfiguredCorrectly_ForErrorStateViewType_SiteLoading() {
        // Given, When
        let config = ErrorStateViewConfiguration.configuration(type: .siteLoading)

        // Then
        let actualTitle = config.title
        let expectedTitle = NSLocalizedString("There was a problem", comment: "No comment (test)")
        XCTAssertEqual(expectedTitle, actualTitle)

        let actualSubtitle = config.subtitle
        let expectedSubtitle = NSLocalizedString("Error communicating with the server, please try again", comment: "No comment (test)")
        XCTAssertEqual(expectedSubtitle, actualSubtitle)

        XCTAssertNil(config.retryActionHandler)
        XCTAssertNil(config.contactSupportActionHandler)
        XCTAssertNil(config.dismissalActionHandler)
    }

    func testErrorStateViewConfiguration_IsConfiguredCorrectly_ForErrorStateViewType_NetworkUnreachable() {
        // Given, When
        let config = ErrorStateViewConfiguration.configuration(type: .networkUnreachable)

        // Then
        let actualTitle = config.title
        let expectedTitle = NSLocalizedString("No internet connection", comment: "No comment (test)")
        XCTAssertEqual(expectedTitle, actualTitle)

        let actualSubtitle = config.subtitle
        let expectedSubtitle: String? = nil
        XCTAssertEqual(expectedSubtitle, actualSubtitle)

        XCTAssertNil(config.retryActionHandler)
        XCTAssertNil(config.contactSupportActionHandler)
        XCTAssertNil(config.dismissalActionHandler)
    }
}
