import XCTest
@testable import WordPress

class QuickStartFactoryTests: XCTestCase {

    private var contextManager: TestContextManager!
    private var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()

        contextManager = TestContextManager()
        context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = contextManager.mainContext
    }

    override func tearDown() {
        super.tearDown()
        context.reset()
        ContextManager.overrideSharedInstance(nil)
    }

    func testCollectionsForExistingSite() {
        // Given
        let blog = newTestBlog(id: 1)
        blog.quickStartType = .existingSite

        // When
        let collections = QuickStartFactory.collections(for: blog)

        // Then
        XCTAssertEqual(collections.count, 1)
        XCTAssertTrue(collections[0] is QuickStartGetToKnowAppCollection)
    }

    func testCollectionsForNewSite() {
        // Given
        let blog = newTestBlog(id: 1)
        blog.quickStartType = .newSite

        // When
        let collections = QuickStartFactory.collections(for: blog)

        // Then
        XCTAssertEqual(collections.count, 2)
        XCTAssertTrue(collections[0] is QuickStartCustomizeToursCollection)
        XCTAssertTrue(collections[1] is QuickStartGrowToursCollection)
    }

    func testReturnsNoCollectionsIfTypeIsUndefined() {
        // Given
        let blog = newTestBlog(id: 1)
        blog.quickStartType = .undefined

        // When
        let collections = QuickStartFactory.collections(for: blog)

        // Then
        XCTAssertTrue(collections.isEmpty)
    }

    func testCollectionsIfTypeIsUndefinedButProgressExists() {
        // Given
        let blog = newTestBlog(id: 1)
        blog.completeTour("test-id")
        blog.quickStartType = .undefined

        // When
        let collections = QuickStartFactory.collections(for: blog)

        // Then
        XCTAssertEqual(collections.count, 2)
        XCTAssertTrue(collections[0] is QuickStartCustomizeToursCollection)
        XCTAssertTrue(collections[1] is QuickStartGrowToursCollection)
    }

    func testToursForExistingSite() {
        // Given
        let blog = newTestBlog(id: 1)
        blog.quickStartType = .existingSite

        // When
        let tours = QuickStartFactory.allTours(for: blog)

        // Then
        XCTAssertEqual(tours.count, 4)
        XCTAssertTrue(tours[0] is QuickStartCheckStatsTour)
        XCTAssertTrue(tours[1] is QuickStartNotificationsTour)
        XCTAssertTrue(tours[2] is QuickStartViewTour)
        XCTAssertTrue(tours[3] is QuickStartFollowTour)
    }

    func testToursForNewSite() {
        // Given
        let blog = newTestBlog(id: 1)
        blog.quickStartType = .newSite

        // When
        let tours = QuickStartFactory.allTours(for: blog)

        // Then
        XCTAssertEqual(tours.count, 9)
        XCTAssertTrue(tours[0] is QuickStartCreateTour)
        XCTAssertTrue(tours[1] is QuickStartSiteTitleTour)
        XCTAssertTrue(tours[2] is QuickStartSiteIconTour)
        XCTAssertTrue(tours[3] is QuickStartReviewPagesTour)
        XCTAssertTrue(tours[4] is QuickStartViewTour)
        XCTAssertTrue(tours[5] is QuickStartShareTour)
        XCTAssertTrue(tours[6] is QuickStartPublishTour)
        XCTAssertTrue(tours[7] is QuickStartFollowTour)
        XCTAssertTrue(tours[8] is QuickStartCheckStatsTour)
    }

    private func newTestBlog(id: Int) -> Blog {
        let blog = ModelTestHelper.insertDotComBlog(context: context)
        blog.dotComID = id as NSNumber
        return blog
    }
}
