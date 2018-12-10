
import XCTest
@testable import WordPress

class SiteAssemblyViewTests: XCTestCase {

    // MARK: SiteAssemblyWizardContent

    func testViewLoaded_BackgroundColor_IsCorrect() {
        // Given
        let creator = SiteCreator()
        let service = MockSiteAssemblyService()
        let viewController = SiteAssemblyWizardContent(creator: creator, service: service)

        // When
        let actualBackgroundColor = viewController.view.backgroundColor

        // Then
        let expectedBackgroundColor = WPStyleGuide.greyLighten30()
        XCTAssertEqual(actualBackgroundColor, expectedBackgroundColor)
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
