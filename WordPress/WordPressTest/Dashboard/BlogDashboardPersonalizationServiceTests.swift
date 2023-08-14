import XCTest
import Nimble

@testable import WordPress

final class BlogDashboardPersonalizationServiceTests: XCTestCase {
    private let repository = InMemoryUserDefaults()

    func testThatSettingsAreSavedPersistently() {
        // Given
        BlogDashboardPersonalizationService(repository: repository, siteID: 1)
            .setEnabled(false, for: .prompts)

        // When new service is created
        let service = BlogDashboardPersonalizationService(repository: repository, siteID: 1)

        // Then settings are retained
        XCTAssertFalse(service.isEnabled(.prompts))
    }

    func testThatServiceNotifiesAboutChanges() {
        // Given
        let service = BlogDashboardPersonalizationService(repository: repository, siteID: 1)
        XCTAssertFalse(service.hasPreference(for: .prompts))

        let expectation = self.expectation(forNotification: .blogDashboardPersonalizationSettingsChanged, object: nil)

        // When
        service.setEnabled(false, for: .prompts)

        // Then notification is sent
        wait(for: [expectation], timeout: 1)
        XCTAssertTrue(service.hasPreference(for: .prompts))
    }

    func testThatSettingsAreSavedPerSite() {
        // Given prompts disabled for site 1
        BlogDashboardPersonalizationService(repository: repository, siteID: 1)
            .setEnabled(false, for: .quickStart)

        // When service is created for site 2
        let service = BlogDashboardPersonalizationService(repository: repository, siteID: 2)

        // Then settings for site 1 are ignored
        XCTAssertTrue(service.isEnabled(.quickStart))
    }

    func testThatUserDefaultsKeysAreSpecifiedForAllPersonalizableCards() {
        let service = BlogDashboardPersonalizationService(repository: repository, siteID: 1)
        for card in DashboardCard.personalizableCards {
            service.setEnabled(false, for: card)
            XCTAssertFalse(service.isEnabled(card))
        }
    }

    func testSetEnabledSiteAgnosticReturnsFalseForTheSameSite() {
        // Given
        BlogDashboardPersonalizationService(repository: repository, siteID: 1)
            .setEnabledSiteAgnostic(false, for: .googleDomains)

        // When new service is created
        let service = BlogDashboardPersonalizationService(repository: repository, siteID: 1)

        // Then settings are retained
        XCTAssertFalse(service.isEnabled(.googleDomains))
    }

    func testSetEnabledSiteAgnosticReturnsFalseForDifferentSite() {
        // Given
        BlogDashboardPersonalizationService(repository: repository, siteID: 1)
            .setEnabledSiteAgnostic(false, for: .googleDomains)

        // When new service is created
        let service = BlogDashboardPersonalizationService(repository: repository, siteID: 2)

        // Then settings are retained
        XCTAssertFalse(service.isEnabled(.googleDomains))
    }

    func testSetEnabledReturnsTrueWhenSiteAgnosticBoolIsTrue() {
        // Given
        BlogDashboardPersonalizationService(repository: repository, siteID: 1)
            .setEnabled(true, for: .googleDomains)
        BlogDashboardPersonalizationService(repository: repository, siteID: 9)
            .setEnabledSiteAgnostic(true, for: .googleDomains)

        // When new service is created
        let service = BlogDashboardPersonalizationService(repository: repository, siteID: 1)

        // Then settings are retained
        XCTAssert(service.isEnabled(.googleDomains))
    }
}
