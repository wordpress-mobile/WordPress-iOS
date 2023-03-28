import XCTest
@testable import WordPress

final class DomainsDashboardCardHelperTests: CoreDataTestCase {
    func testShouldShowCardEnabledFeatureFlagAndHostedAtWPcom() {
        let blog = BlogBuilder(mainContext)
            .isHostedAtWPcom()
            .with(atomic: false)
            .with(isAdmin: true)
            .with(registeredDomainCount: 0)
            .with(hasDomainCredit: false)
            .build()

        let result = DomainsDashboardCardHelper.shouldShowCard(for: blog, isJetpack: true, featureFlagEnabled: true)

        XCTAssertTrue(result, "Card should show for WPcom hosted blogs")
    }

    func testShouldShowCardEnabledFeatureFlagAndAtomic() {
        let blog = BlogBuilder(mainContext)
            .isNotHostedAtWPcom()
            .with(atomic: true)
            .with(isAdmin: true)
            .with(registeredDomainCount: 0)
            .with(hasDomainCredit: false)
            .build()

        let result = DomainsDashboardCardHelper.shouldShowCard(for: blog, isJetpack: true, featureFlagEnabled: true)

        XCTAssertTrue(result, "Card should show for Atomic blogs")
    }

    func testShouldNotShowCardNotAdmin() {
        let blog = BlogBuilder(mainContext)
            .isHostedAtWPcom()
            .with(atomic: false)
            .with(isAdmin: false)
            .with(registeredDomainCount: 0)
            .with(hasDomainCredit: false)
            .build()

        let result = DomainsDashboardCardHelper.shouldShowCard(for: blog, isJetpack: true, featureFlagEnabled: true)

        XCTAssertFalse(result, "Card should not show for non-admin users")
    }

    func testShouldNotShowCardHasOtherDomains() {
        let blog = BlogBuilder(mainContext)
            .isHostedAtWPcom()
            .with(atomic: false)
            .with(isAdmin: true)
            .with(registeredDomainCount: 2)
            .with(hasDomainCredit: false)
            .build()

        let result = DomainsDashboardCardHelper.shouldShowCard(for: blog, isJetpack: true, featureFlagEnabled: true)

        XCTAssertFalse(result, "Card should not show for blogs with more than one domain")
    }

    func testShouldNotShowCardHasDomainCredit() {
        let blog = BlogBuilder(mainContext)
            .isHostedAtWPcom()
            .with(atomic: false)
            .with(isAdmin: true)
            .with(registeredDomainCount: 0)
            .with(hasDomainCredit: true)
            .build()

        let result = DomainsDashboardCardHelper.shouldShowCard(for: blog, isJetpack: true, featureFlagEnabled: true)

        XCTAssertFalse(result, "Card should not show for blogs with domain credit")
    }

    func testShouldNotShowCardFeatureFlagDisabled() {
        let blog = BlogBuilder(mainContext)
            .isHostedAtWPcom()
            .with(atomic: false)
            .with(isAdmin: true)
            .with(registeredDomainCount: 0)
            .with(hasDomainCredit: false)
            .build()

        let result = DomainsDashboardCardHelper.shouldShowCard(for: blog, isJetpack: true, featureFlagEnabled: false)

        XCTAssertFalse(result, "Card should not show when the feature flag is disabled")
    }
}
