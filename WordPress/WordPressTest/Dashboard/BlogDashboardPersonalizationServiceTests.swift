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

    func testSetEnabledForAllSitesReturnsFalseForTheSameSite() {
        // Given
        let service = BlogDashboardPersonalizationService(repository: repository, siteID: 1)

        // When
        service.setEnabled(false, for: .googleDomains)

        // Then
        XCTAssertFalse(service.isEnabled(.googleDomains))
    }

    func testSetEnabledForAllSitesReturnsFalseForDifferentSite() {
        // Given
        let service1 = BlogDashboardPersonalizationService(repository: repository, siteID: 1)
        let service2 = BlogDashboardPersonalizationService(repository: repository, siteID: 2)

        // When
        service1.setEnabled(false, for: .googleDomains)

        // Then settings are retained
        XCTAssertFalse(service2.isEnabled(.googleDomains))
    }

    func testHasPreferenceReturnsTrueWhenValueSetForAllSites() {
        // Given
        let service = BlogDashboardPersonalizationService(repository: repository, siteID: 1)

        // When
        service.setEnabled(false, for: .googleDomains)

        // Then
        XCTAssert(service.hasPreference(for: .googleDomains))
    }

    func testHasPreferenceReturnsTrueWhenValueSetForASite() {
        // Given
        let service = BlogDashboardPersonalizationService(repository: repository, siteID: 1)

        // When
        service.setEnabled(false, for: .blaze)

        // Then
        XCTAssert(service.hasPreference(for: .blaze))
    }

    func testHasPreferenceReturnsFalseWhenNoPreferenceIsSet() {
        let service = BlogDashboardPersonalizationService(repository: repository, siteID: 1)

        XCTAssertFalse(service.hasPreference(for: .googleDomains))
    }
}
