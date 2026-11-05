import Testing
import WordPressData

@testable import WordPress

@MainActor
struct DesignCardEligibilityTests {
    private let contextManager = ContextManager.forTesting()
    private let record = BlankSiteRecord(repository: InMemoryUserDefaults())

    @Test func showsForBlankSiteInJetpack() {
        let blog = makeBlog(siteID: 1)
        record.insert(siteID: 1)

        #expect(DashboardDesignCardCell.shouldShowCard(for: blog, isJetpack: true, record: record))
    }

    @Test func hiddenForSiteOutsideTheRecord() {
        let blog = makeBlog(siteID: 1)
        record.insert(siteID: 2)

        #expect(!DashboardDesignCardCell.shouldShowCard(for: blog, isJetpack: true, record: record))
    }

    @Test func hiddenInWordPressApp() {
        let blog = makeBlog(siteID: 1)
        record.insert(siteID: 1)

        #expect(!DashboardDesignCardCell.shouldShowCard(for: blog, isJetpack: false, record: record))
    }

    @Test func isTheFirstLocalCard() {
        #expect(DashboardCard.allCases.prefix(2) == [.dynamic, .design])
    }

    @Test func isNotPersonalizable() {
        #expect(!DashboardCard.personalizableCards.contains(.design))
        #expect(DashboardCard.design.blogDashboardPersonalizationKey == nil)
    }

    private func makeBlog(siteID: Int) -> Blog {
        BlogBuilder(contextManager.mainContext, dotComID: NSNumber(value: siteID)).isHostedAtWPcom().build()
    }
}
