import XCTest
@testable import WordPress

final class DomainsDashboardCardHelperTests: CoreDataTestCase {
    func testShouldShowCardBlogSupportsDomains() {
        let blog = BlogBuilder(mainContext)
            .with(supportsDomains: true)
            .with(domainCount: 1, of: .wpCom)
            .with(domainCount: 0, of: .registered)
            .with(hasDomainCredit: false)
            .build()

        let result = DomainsDashboardCardHelper.shouldShowCard(for: blog, isJetpack: true, featureFlagEnabled: true)

        XCTAssertTrue(result, "Card should show for WPcom hosted blogs")
    }

    func testShouldNotShowCardBlogDoesNotSupportDomains() {
        let blog = BlogBuilder(mainContext)
            .with(supportsDomains: false)
            .with(domainCount: 1, of: .wpCom)
            .with(domainCount: 0, of: .registered)
            .with(hasDomainCredit: false)
            .build()

        let result = DomainsDashboardCardHelper.shouldShowCard(for: blog, isJetpack: true, featureFlagEnabled: true)

        XCTAssertFalse(result, "Card should show for blogs that do not support domains")
    }

    func testShouldNotShowCardHasOtherDomains() {
        let blog = BlogBuilder(mainContext)
            .with(supportsDomains: true)
            .with(domainCount: 1, of: .wpCom)
            .with(domainCount: 2, of: .registered)
            .with(hasDomainCredit: false)
            .build()

        let result = DomainsDashboardCardHelper.shouldShowCard(for: blog, isJetpack: true, featureFlagEnabled: true)

        XCTAssertFalse(result, "Card should not show for blogs with more than one domain")
    }

    func testShouldNotShowCardHasDomainCredit() {
        let blog = BlogBuilder(mainContext)
            .with(supportsDomains: true)
            .with(domainCount: 1, of: .wpCom)
            .with(domainCount: 0, of: .registered)
            .with(hasDomainCredit: true)
            .build()

        let result = DomainsDashboardCardHelper.shouldShowCard(for: blog, isJetpack: true, featureFlagEnabled: true)

        XCTAssertFalse(result, "Card should not show for blogs with domain credit")
    }

    func testShouldNotShowCardWhenDomainInformationIsNotLoaded() {
        let blog = BlogBuilder(mainContext)
            .with(supportsDomains: true)
            .with(domainCount: 0, of: .wpCom)
            .with(domainCount: 0, of: .registered)
            .with(hasDomainCredit: false)
            .build()

        let result = DomainsDashboardCardHelper.shouldShowCard(for: blog, isJetpack: true, featureFlagEnabled: true)

        XCTAssertFalse(result, "Card should not until domain information is loaded")
    }

    func testShouldNotShowCardFeatureFlagDisabled() {
        let blog = BlogBuilder(mainContext)
            .with(supportsDomains: true)
            .with(domainCount: 1, of: .wpCom)
            .with(domainCount: 0, of: .registered)
            .with(hasDomainCredit: false)
            .build()

        let result = DomainsDashboardCardHelper.shouldShowCard(for: blog, isJetpack: true, featureFlagEnabled: false)

        XCTAssertFalse(result, "Card should not show when the feature flag is disabled")
    }
}
