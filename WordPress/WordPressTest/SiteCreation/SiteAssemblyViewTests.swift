
import XCTest
@testable import WordPress

class SiteAssemblyViewTests: XCTestCase {

    // MARK: SiteAssemblyContentView

    func testContentView_BackgroundColor_IsCorrect() {
        // Given
        let contentView = SiteAssemblyContentView()

        // When
        let actualBackgroundColor = contentView.backgroundColor

        // Then
        let expectedBackgroundColor = WPStyleGuide.greyLighten30()
        XCTAssertEqual(actualBackgroundColor, expectedBackgroundColor)
    }

    // MARK: SiteAssemblyWizardContent

    func testViewLoaded_IsSiteAssemblyContentView() {
        // Given
        let creator = SiteCreator()
        let service = MockSiteAssemblyService()
        let viewController = SiteAssemblyWizardContent(creator: creator, service: service)

        // When
        let contentView = viewController.view

        // Then
        XCTAssertNotNil(contentView)
        let actualView = contentView!
        XCTAssertTrue(actualView.isKind(of: SiteAssemblyContentView.self))
    }

    func testViewLoaded_StatusBar_DefaultContent() {
        // Given
        let creator = SiteCreator()
        let service = MockSiteAssemblyService()
        let viewController = SiteAssemblyWizardContent(creator: creator, service: service)

        // When
        _ = viewController.view
        let actualStatusBarStyle = viewController.preferredStatusBarStyle

        // Then
        let expectedStatusBarStyle = UIStatusBarStyle.default
        XCTAssertEqual(actualStatusBarStyle, expectedStatusBarStyle)
    }
}
