import XCTest
@testable import WordPress

final class BlogListViewModelTests: CoreDataTestCase {
    private var viewModel: BlogListViewModel!

    override func setUp() {
        super.setUp()

        viewModel = BlogListViewModel(contextManager: contextManager)
    }

    // MARK: - Tests for Retrieval Functions

    func testRecentSitesWithNoData() {
        XCTAssertTrue(viewModel.recentSites.isEmpty)
    }

    func testRecentSitesWithValidData() throws {
        let siteID = 34984
        let site = BlogBuilder(mainContext)
            .with(dotComID: siteID)
            .with(lastUsed: Date())
            .build()
        try mainContext.save()

        viewModel = BlogListViewModel(contextManager: contextManager)

        XCTAssertEqual(viewModel.recentSites.first?.id, site.objectID)
        XCTAssertEqual(viewModel.recentSites.count, 1)
    }

    func testAllSitesAreDisplayedAndSortedByName() throws {
        let siteID1 = 34984
        let _ = BlogBuilder(mainContext)
            .with(siteName: "A")
            .with(dotComID: siteID1)
            .with(lastUsed: Date())
            .build()

        let siteID2 = 54317
        let _ = BlogBuilder(mainContext)
            .with(siteName: "51 Zone")
            .with(dotComID: siteID2)
            .with(pinnedDate: Date())
            .build()

        let siteID3 = 13287
        let _ = BlogBuilder(mainContext)
            .with(siteName: "a")
            .with(dotComID: siteID3)
            .with(pinnedDate: Date())
            .build()

        let siteID4 = 54317
        let _ = BlogBuilder(mainContext)
            .with(siteName: ".Org")
            .with(dotComID: siteID4)
            .with(pinnedDate: Date())
            .build()

        let siteID5 = 43788
        let _ = BlogBuilder(mainContext)
            .with(siteName: "C")
            .with(dotComID: siteID5)
            .build()

        try mainContext.save()

        viewModel = BlogListViewModel(contextManager: contextManager)

        let displayedNames = viewModel.allSites.map(\.title)
        XCTAssertEqual(displayedNames, [".Org", "51 Zone", "a", "A", "C"])
    }
}
