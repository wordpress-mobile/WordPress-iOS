import WordPressShared
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

    func testTopSitesIncludesCurrentSite() throws {
        // Given: Create test sites
        let siteA = BlogBuilder(mainContext)
            .with(siteName: "A Site")
            .with(dotComID: 1)
            .build()

        let siteB = BlogBuilder(mainContext)
            .with(siteName: "B Site")
            .with(dotComID: 2)
            .build()

        let siteC = BlogBuilder(mainContext)
            .with(siteName: "C Site")
            .with(dotComID: 3)
            .build()

        let siteZ = BlogBuilder(mainContext)
            .with(siteName: "Z Site")
            .with(dotComID: 4)
            .build()

        try mainContext.save()

        // When:  Set up recent sites (excluding Z)
        recentSitesService.touch(blog: siteA)
        recentSitesService.touch(blog: siteB)
        recentSitesService.touch(blog: siteC)

        setupViewModel()

        // Mock the sidebarViewModel and set the current site to Z (which is not in recent sites)
        let mockSidebarViewModel = SidebarViewModel()
        mockSidebarViewModel.selection = .blog(TaggedManagedObjectID(siteZ))
        viewModel.sidebarViewModel = mockSidebarViewModel

        // Then: Verify Z is included in topSites even though it's not a recent site
        XCTAssertTrue(viewModel.topSites.contains(where: { $0.id == TaggedManagedObjectID(siteZ) }))
    }

    func testTopSitesRespectsSiteLimit() throws {
        // Given: Create 6 test sites (more than the current display limit of 4)
        let sites = (1...6).map { i in
            return BlogBuilder(mainContext)
                .with(siteName: "Site \(i)")
                .with(dotComID: i)
                .build()
        }

        try mainContext.save()

        // When: Touch all sites to make them recent
        sites.forEach { recentSitesService.touch(blog: $0) }

        setupViewModel()

        // Then: Verify topSites doesn't exceed the display limit
        XCTAssertEqual(viewModel.topSites.count, SidebarView.displayedSiteLimit)
    }

    func testTopSitesPrioritizesCurrentSiteThenRecentSites() throws {
        // Given
        // Create test sites with names that would be sorted differently alphabetically
        let siteA = BlogBuilder(mainContext)
            .with(siteName: "A Site")
            .with(dotComID: 1)
            .build()

        let siteB = BlogBuilder(mainContext)
            .with(siteName: "B Site")
            .with(dotComID: 2)
            .build()

        let siteY = BlogBuilder(mainContext)
            .with(siteName: "Y Site")
            .with(dotComID: 3)
            .build()

        let siteZ = BlogBuilder(mainContext)
            .with(siteName: "Z Site")
            .with(dotComID: 4)
            .build()

        try mainContext.save()

        // When
        // Set up recent sites in order: B, Y
        recentSitesService.touch(blog: siteB)
        recentSitesService.touch(blog: siteY)

        setupViewModel()

        // Make Z the current site
        let mockSidebarViewModel = SidebarViewModel()
        mockSidebarViewModel.selection = .blog(TaggedManagedObjectID(siteZ))
        viewModel.sidebarViewModel = mockSidebarViewModel

        // Then
        // Verify all sites are sorted alphabetically, but Z is included despite not being recent
        let siteNames = viewModel.topSites.map(\.title)
        XCTAssertTrue(siteNames.contains("Z Site"), "Current site should be included")
        XCTAssertTrue(isSorted(siteNames), "Sites should be sorted alphabetically")
    }
}

private extension BlogListViewModelTests {
    // Helper method to check if an array is sorted
    func isSorted(_ array: [String]) -> Bool {
        for i in 0..<(array.count - 1) {
            if array[i].localizedCaseInsensitiveCompare(array[i + 1]) == .orderedDescending {
                return false
            }
        }
        return true
    }
}
