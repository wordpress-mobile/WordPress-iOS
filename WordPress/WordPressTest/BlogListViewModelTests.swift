import XCTest
@testable import WordPress

final class BlogListViewModelTests: CoreDataTestCase {
    private var viewModel: BlogListViewModel!
    private let recentSitesService = RecentSitesService(database: EphemeralKeyValueDatabase())

    override func setUp() {
        super.setUp()

        setupViewModel()
    }

    private func setupViewModel() {
        viewModel = BlogListViewModel(contextManager: contextManager, recentSitesService: recentSitesService)
    }

    // MARK: - Tests for Retrieval Functions

    func testRecentSitesWithNoData() {
        XCTAssertTrue(viewModel.recentSites.isEmpty)
    }

    func testRecentSitesWithValidData() throws {
        let siteID = 34984
        let site = BlogBuilder(mainContext)
            .with(dotComID: siteID)
            .with(url: "test")
            .build()
        try mainContext.save()

        recentSitesService.touch(blog: site)

        setupViewModel()

        XCTAssertEqual(viewModel.recentSites.first?.id, TaggedManagedObjectID(site))
        XCTAssertEqual(viewModel.recentSites.count, 1)
    }

    func testAllSitesAreDisplayedAndSortedByName() throws {
        let siteID1 = 34984
        let _ = BlogBuilder(mainContext)
            .with(siteName: "A")
            .with(dotComID: siteID1)
            .build()

        let siteID2 = 54317
        let _ = BlogBuilder(mainContext)
            .with(siteName: "51 Zone")
            .with(dotComID: siteID2)
            .build()

        let siteID4 = 54317
        let _ = BlogBuilder(mainContext)
            .with(siteName: ".Org")
            .with(dotComID: siteID4)
            .build()

        let siteID5 = 43788
        let _ = BlogBuilder(mainContext)
            .with(siteName: "C")
            .with(dotComID: siteID5)
            .build()

        try mainContext.save()

        setupViewModel()

        let displayedNames = viewModel.allSites.map(\.title)
        XCTAssertEqual(displayedNames, [".Org", "51 Zone", "A", "C"])
    }

    func testTopSites() throws {
        // Prepare data:
        //
        // - Create 10 blogs.
        //   - id: 1 to 9.
        //   - title: "Site $id"
        // - Blog id 5, 6, 7 are recently used blogs.

        // The key of `blogs` is blog id.
        let blogs: [Int: Blog] = (1...9).reduce(into: [:]) { result, dotComId in
            let blog = BlogBuilder(mainContext)
                .with(siteName: "Site \(dotComId)")
                .with(dotComID: dotComId)
                .build()
            result[dotComId] = blog
        }
        try mainContext.save()

        recentSitesService.touch(blog: blogs[5]!)
        recentSitesService.touch(blog: blogs[6]!)
        recentSitesService.touch(blog: blogs[7]!)

        setupViewModel()

        XCTAssertEqual(
            viewModel.topSites(limit: 2, containing: nil).map { $0.title },
            ["Site 5", "Site 6"]
        )

        XCTAssertEqual(
            viewModel.topSites(limit: 3, containing: nil).map { $0.title },
            ["Site 5", "Site 6", "Site 7"]
        )

        XCTAssertEqual(
            viewModel.topSites(limit: 4, containing: nil).map { $0.title },
            ["Site 1", "Site 5", "Site 6", "Site 7"]
        )

        XCTAssertEqual(
            viewModel.topSites(limit: 3, containing: TaggedManagedObjectID(blogs[5]!)).map { $0.title },
            ["Site 5", "Site 6", "Site 7"]
        )

        XCTAssertEqual(
            viewModel.topSites(limit: 3, containing: TaggedManagedObjectID(blogs[8]!)).map { $0.title },
            ["Site 5", "Site 6", "Site 8"]
        )
    }
}
