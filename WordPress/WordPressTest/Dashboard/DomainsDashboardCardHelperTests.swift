import XCTest
@testable import WordPress

final class DomainsDashboardCardHelperTests: CoreDataTestCase {
    func testShouldShowCardBlogSupportsDomains() {
        let blog = BlogBuilder(mainContext)
            .with(supportsDomains: true)
            .with(registeredDomainCount: 0)
            .with(hasDomainCredit: false)
            .build()

        let result = DomainsDashboardCardHelper.shouldShowCard(for: blog, isJetpack: true, featureFlagEnabled: true)

        XCTAssertTrue(result, "Card should show for WPcom hosted blogs")
    }

    func testShouldNotShowCardBlogDoesNotSupportDomains() {
        let blog = BlogBuilder(mainContext)
            .with(supportsDomains: false)
            .with(registeredDomainCount: 0)
            .with(hasDomainCredit: false)
            .build()

        let result = DomainsDashboardCardHelper.shouldShowCard(for: blog, isJetpack: true, featureFlagEnabled: true)

        XCTAssertFalse(result, "Card should show for blogs that do not support domains")
    }

    func testShouldNotShowCardHasOtherDomains() {
        let blog = BlogBuilder(mainContext)
            .with(supportsDomains: true)
            .with(registeredDomainCount: 2)
            .with(hasDomainCredit: false)
            .build()

        let result = DomainsDashboardCardHelper.shouldShowCard(for: blog, isJetpack: true, featureFlagEnabled: true)

        XCTAssertFalse(result, "Card should not show for blogs with more than one domain")
    }

    func testShouldNotShowCardHasDomainCredit() {
        let blog = BlogBuilder(mainContext)
            .with(supportsDomains: true)
            .with(registeredDomainCount: 0)
            .with(hasDomainCredit: true)
            .build()

        let result = DomainsDashboardCardHelper.shouldShowCard(for: blog, isJetpack: true, featureFlagEnabled: true)

        XCTAssertFalse(result, "Card should not show for blogs with domain credit")
    }

    func testShouldNotShowCardFeatureFlagDisabled() {
        let blog = BlogBuilder(mainContext)
            .with(supportsDomains: true)
            .with(registeredDomainCount: 0)
            .with(hasDomainCredit: false)
            .build()

        let result = DomainsDashboardCardHelper.shouldShowCard(for: blog, isJetpack: true, featureFlagEnabled: false)

        XCTAssertFalse(result, "Card should not show when the feature flag is disabled")
    }
}
