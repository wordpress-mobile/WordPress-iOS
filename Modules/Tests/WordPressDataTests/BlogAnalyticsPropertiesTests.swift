import CoreData
import Testing
import WordPressShared
@testable import WordPressData

@MainActor
struct BlogAnalyticsPropertiesTests {
    private let contextManager = ContextManager.forTesting()
    private var mainContext: NSManagedObjectContext { contextManager.mainContext }

    @Test func snapshotCapturesDotComIDAndBlogSiteType() {
        let blog = BlogBuilder(mainContext, dotComID: NSNumber(value: 42))
            .with(isWPForTeamsSite: false)
            .build()

        let properties = blog.analyticsProperties

        #expect(properties.dotComID == 42)
        #expect(!properties.isWPForTeams)
    }

    @Test func snapshotCapturesP2SiteType() {
        let blog = BlogBuilder(mainContext, dotComID: NSNumber(value: 7))
            .with(isWPForTeamsSite: true)
            .build()

        #expect(blog.analyticsProperties.isWPForTeams)
    }

    @Test func selfHostedSiteHasNoDotComID() {
        let blog = BlogBuilder(mainContext, dotComID: nil).build()

        #expect(blog.analyticsProperties.dotComID == nil)
    }
}
