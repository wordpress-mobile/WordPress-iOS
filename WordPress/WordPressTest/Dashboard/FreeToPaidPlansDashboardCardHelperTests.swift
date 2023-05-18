import XCTest
@testable import WordPress

final class FreeToPaidPlansDashboardCardHelperTests: CoreDataTestCase {
    func testShouldShowCardWithFreePlanAndNoMappedDomain() {
        let blog = BlogBuilder(mainContext)
            .with(supportsDomains: true)
            .with(domainCount: 1, of: .wpCom)
            .with(hasMappedDomain: false)
            .with(hasPaidPlan: false)
            .build()

        let result = FreeToPaidPlansDashboardCardHelper.shouldShowCard(for: blog, isJetpack: true, featureFlagEnabled: true)

        XCTAssertTrue(result, "Card should show for blogs with a free plan and no mapped domain")
    }

    func testShouldNotShowCardWithoutFreePlan() {
        let blog = BlogBuilder(mainContext)
            .with(supportsDomains: true)
            .with(domainCount: 1, of: .wpCom)
            .with(hasMappedDomain: false)
            .with(hasPaidPlan: true)
            .build()

        let result = FreeToPaidPlansDashboardCardHelper.shouldShowCard(for: blog, isJetpack: true, featureFlagEnabled: true)

        XCTAssertFalse(result, "Card should not show for blogs without a free plan")
    }

    func testShouldNotShowCardWithMappedDomain() {
        let blog = BlogBuilder(mainContext)
            .with(supportsDomains: true)
            .with(domainCount: 1, of: .wpCom)
            .with(domainCount: 1, of: .registered)
            .with(hasMappedDomain: true)
            .with(hasPaidPlan: false)
            .build()

        let result = FreeToPaidPlansDashboardCardHelper.shouldShowCard(for: blog, isJetpack: true, featureFlagEnabled: true)

        XCTAssertFalse(result, "Card should not show for blogs with a mapped domain")
    }

    func testShouldNotShowCardWhenDomainInformationIsNotLoaded() {
        let blog = BlogBuilder(mainContext)
            .with(supportsDomains: true)
            .with(domainCount: 0, of: .wpCom)
            .with(hasMappedDomain: false)
            .with(hasPaidPlan: false)
            .build()

        let result = FreeToPaidPlansDashboardCardHelper.shouldShowCard(for: blog, isJetpack: true, featureFlagEnabled: true)

        XCTAssertFalse(result, "Card should not show until domain information is loaded")
    }

    func testShouldNotShowCardFeatureFlagDisabled() {
        let blog = BlogBuilder(mainContext)
            .with(supportsDomains: true)
            .with(domainCount: 1, of: .wpCom)
            .with(hasMappedDomain: false)
            .with(hasPaidPlan: false)
            .build()

        let result = FreeToPaidPlansDashboardCardHelper.shouldShowCard(for: blog, isJetpack: true, featureFlagEnabled: false)

        XCTAssertFalse(result, "Card should not show when the feature flag is disabled")
    }
}
