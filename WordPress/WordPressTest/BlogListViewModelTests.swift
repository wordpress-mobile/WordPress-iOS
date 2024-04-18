import XCTest
@testable import WordPress

final class BlogListViewModelTests: CoreDataTestCase {
    private var viewModel: BlogListViewModel!

    override func setUp() {
        super.setUp()

        viewModel = BlogListViewModel(contextManager: contextManager)
    }

    // MARK: - Tests for Retrieval Functions
    func testPinnedSitesWithNoData() {
        XCTAssertTrue(viewModel.pinnedSites.isEmpty)
    }

    func testPinnedSitesWithValidData() throws {
        let siteID = 34984
        let _ = BlogBuilder(mainContext)
            .with(dotComID: siteID)
            .with(pinnedDate: Date())
            .build()
        try mainContext.save()

        viewModel = BlogListViewModel(contextManager: contextManager)

        XCTAssertEqual(viewModel.pinnedSites.first?.id, 34984)
    }

    func testRecentSitesWithNoData() {
        XCTAssertTrue(viewModel.recentSites.isEmpty)
    }

    func testRecentSitesWithValidData() throws {
        let siteID = 34984
        let _ = BlogBuilder(mainContext)
            .with(dotComID: siteID)
            .with(lastUsed: Date())
            .with(pinnedDate: nil)
            .build()
        try mainContext.save()

        viewModel = BlogListViewModel(contextManager: contextManager)

        XCTAssertEqual(viewModel.recentSites.first?.id, siteID as NSNumber)
        XCTAssertEqual(viewModel.recentSites.count, 1)
    }

    func testAllRemainingSitesWithNoData() {
        XCTAssertTrue(viewModel.allRemainingSites.isEmpty)
    }

    func testAllRemainingSitesWithValidData() throws {
        let siteID1 = 34984
        let _ = BlogBuilder(mainContext)
            .with(dotComID: siteID1)
            .with(lastUsed: Date())
            .build()

        let siteID2 = 13287
        let _ = BlogBuilder(mainContext)
            .with(dotComID: siteID2)
            .with(pinnedDate: Date())
            .build()

        let siteID3 = 43788
        let _ = BlogBuilder(mainContext)
            .with(dotComID: siteID3)
            .build()
        try mainContext.save()

        viewModel = BlogListViewModel(contextManager: contextManager)

        XCTAssertEqual(viewModel.allRemainingSites.first?.id, siteID3 as NSNumber)
        XCTAssertEqual(viewModel.allRemainingSites.count, 1)
    }

    func testTogglePinnedSiteUpdatesPinnedSites() throws {
        let id = 23948
        let blog = BlogBuilder(mainContext)
            .with(dotComID: id)
            .build()
        try mainContext.save()

        viewModel.togglePinnedSite(siteID: blog.dotComID)

        XCTAssertEqual(viewModel.pinnedSites.first?.id, id as NSNumber)
        XCTAssertEqual(viewModel.pinnedSites.count, 1)
    }

    func testSiteSelectedUpdatesLastUsedDate() throws {
        let siteID = 4839
        let _ = BlogBuilder(mainContext)
            .with(dotComID: siteID)
            .with(lastUsed: nil)
            .build()
        try mainContext.save()

        viewModel.siteSelected(siteID: siteID as NSNumber)

        XCTAssertEqual(viewModel.recentSites.first?.id, siteID as NSNumber)
    }
}
