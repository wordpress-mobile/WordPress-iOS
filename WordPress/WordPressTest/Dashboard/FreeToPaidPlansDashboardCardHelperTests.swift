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

        let result = FreeToPaidPlansDashboardCardHelper.shouldShowCard(for: blog)

        XCTAssertTrue(result, "Card should show for blogs with a free plan and no mapped domain")
    }

    func testShouldNotShowCardWithoutFreePlan() {
        let blog = BlogBuilder(mainContext)
            .with(supportsDomains: true)
            .with(domainCount: 1, of: .wpCom)
            .with(hasMappedDomain: false)
            .with(hasPaidPlan: true)
            .build()

        let result = FreeToPaidPlansDashboardCardHelper.shouldShowCard(for: blog)

        XCTAssertFalse(result, "Card should not show for blogs without a free plan")
    }

    func testShouldShowCardWithMappedDomain() {
        let blog = BlogBuilder(mainContext)
            .with(supportsDomains: true)
            .with(domainCount: 1, of: .wpCom)
            .with(domainCount: 1, of: .registered)
            .with(hasMappedDomain: true)
            .with(hasPaidPlan: false)
            .build()

        let result = FreeToPaidPlansDashboardCardHelper.shouldShowCard(for: blog)

        XCTAssertTrue(result, "Card should still be shown for blogs with a mapped domain and with a free plan")
    }
}
