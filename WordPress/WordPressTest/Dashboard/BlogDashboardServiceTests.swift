import XCTest
import Nimble

@testable import WordPress

class BlogDashboardServiceTests: CoreDataTestCase {
    private var context: NSManagedObjectContext!

    private var service: BlogDashboardService!
    private var remoteServiceMock: DashboardServiceRemoteMock!
    private var persistenceMock: BlogDashboardPersistenceMock!
    private var repositoryMock: InMemoryUserDefaults!
    private var postsParserMock: BlogDashboardPostsParserMock!
    private var remoteFeatureFlagStore: RemoteFeatureFlagStoreMock!

    private let featureFlags = FeatureFlagOverrideStore()

    private let wpComID = 123456

    override func setUp() {
        super.setUp()

        // Simulate the app is signed in with a WP.com account
        contextManager.useAsSharedInstance(untilTestFinished: self)
        let accountService = AccountService(coreDataStack: contextManager)
        _ = accountService.createOrUpdateAccount(withUsername: "username", authToken: "token")

        remoteServiceMock = DashboardServiceRemoteMock()
        persistenceMock = BlogDashboardPersistenceMock()
        repositoryMock = InMemoryUserDefaults()
        postsParserMock = BlogDashboardPostsParserMock(managedObjectContext: mainContext)
        remoteFeatureFlagStore = RemoteFeatureFlagStoreMock()
        service = BlogDashboardService(
            managedObjectContext: mainContext,
            // Notice these three boolean make the test run as if the app was Jetpack.
            //
            // What would be the additional effor to test the remaining 5 configurations?
            // Is there something we can do to reduce the combinatorial space?
            //
            // See also https://github.com/wordpress-mobile/WordPress-iOS/pull/21740
            isJetpack: true,
            isDotComAvailable: true,
            shouldShowJetpackFeatures: true,
            remoteService: remoteServiceMock,
            persistence: persistenceMock,
            repository: repositoryMock,
            postsParser: postsParserMock,
            remoteFeatureFlagStore: remoteFeatureFlagStore
        )

        // The state of the world these tests assume relies on certain feature flags.
        //
        // Similarly to the isJetpack, isDotComAvailable, etc above, it would be ideal to inject these at call site to:
        // 1. Make the dependency on that bit of information explicit
        // 2. Allow for testing all combinations
        //
        // At the time of writing, the priority was getting some tests for new code to pass under the important Jetpac user path.
        // As such, here are a bunch of global-state feature flags overrides.
        try? featureFlags.override(RemoteFeatureFlag.activityLogDashboardCard, withValue: true)
        try? featureFlags.override(RemoteFeatureFlag.pagesDashboardCard, withValue: true)
        try? featureFlags.override(FeatureFlag.googleDomainsCard, withValue: false)
        try? featureFlags.override(RemoteFeatureFlag.dynamicDashboardCards, withValue: true)
    }

    override func tearDown() {
        super.tearDown()
        context = nil

        try? featureFlags.override(RemoteFeatureFlag.activityLogDashboardCard, withValue: RemoteFeatureFlag.activityLogDashboardCard.originalValue)
        try? featureFlags.override(RemoteFeatureFlag.pagesDashboardCard, withValue: RemoteFeatureFlag.pagesDashboardCard.originalValue)
        try? featureFlags.override(FeatureFlag.googleDomainsCard, withValue: FeatureFlag.googleDomainsCard.originalValue)
    }

    func testCallServiceWithCorrectIDAndCards() {
        let expect = expectation(description: "Request the correct ID")

        let blog = newTestBlog(id: wpComID, context: mainContext)

        service.fetch(blog: blog) { _ in
            XCTAssertEqual(self.remoteServiceMock.didCallWithBlogID, self.wpComID)
            XCTAssertEqual(self.remoteServiceMock.didCallWithDeviceId, "Test")
            XCTAssertEqual(self.remoteServiceMock.didRequestCards, ["todays_stats", "posts", "pages", "activity", "dynamic"])
            expect.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testCreateSectionForPosts() {
        let expect = expectation(description: "Parse drafts and scheduled")
        remoteServiceMock.respondWith = .withDraftAndSchedulePosts

        let blog = newTestBlog(id: wpComID, context: mainContext)

        service.fetch(blog: blog) { cards in
            let draftPostsCardItem = cards.first(where: { $0.cardType == .draftPosts })?.normal()
            let scheduledPostsCardItem = cards.first(where: { $0.cardType == .scheduledPosts })?.normal()

            // Posts section exists
            XCTAssertNotNil(draftPostsCardItem)
            XCTAssertNotNil(scheduledPostsCardItem)

            // Has published is `true`
            XCTAssertTrue(draftPostsCardItem!.apiResponse!.posts!.value!.hasPublished!)

            // 3 scheduled item
            XCTAssertEqual(draftPostsCardItem!.apiResponse!.posts!.value!.draft!.count, 3)

            // 1 scheduled item
            XCTAssertEqual(draftPostsCardItem!.apiResponse!.posts!.value!.scheduled!.count, 1)

            // Has published is `true`
            XCTAssertTrue(scheduledPostsCardItem!.apiResponse!.posts!.value!.hasPublished!)

            // 3 scheduled item
            XCTAssertEqual(scheduledPostsCardItem!.apiResponse!.posts!.value!.draft!.count, 3)

            // 1 scheduled item
            XCTAssertEqual(scheduledPostsCardItem!.apiResponse!.posts!.value!.scheduled!.count, 1)

            expect.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testPages() {
        let expect = expectation(description: "Parse pages")

        let blog = newTestBlog(id: wpComID, context: mainContext)

        service.fetch(blog: blog) { cards in
            let pagesCardItem = cards.first(where: { $0.cardType == .pages })?.normal()

            // Pages section exists
            XCTAssertNotNil(pagesCardItem)

            // 2 page items
            XCTAssertEqual(pagesCardItem!.apiResponse!.pages!.value!.count, 2)

            expect.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testActivityLog() {
        let expect = expectation(description: "Parse activities")

        // Will fail with logged in user.
        //
        // It happens because for some reason the logic that should add activity as one of the type of cards to fetch doesn't do that.
        let blog = newTestBlog(id: wpComID, context: mainContext)

        service.fetch(blog: blog) { cards in
            guard let activityCardItem = cards.first(where: { $0.cardType == .activityLog })?.normal() else {
                return XCTFail("Unexpectedly found nil Optional")
            }

            guard let apiResponse = activityCardItem.apiResponse else {
                return XCTFail("Unexpectedly found nil Optional")
            }

            guard let activity = apiResponse.activity else {
                return XCTFail("Unexpectedly found nil Optional")
            }

            guard let value = activity.value else {
                return XCTFail("Unexpectedly found nil Optional")
            }

            guard let current = value.current else {
                return XCTFail("Unexpectedly found nil Optional")
            }

            guard let orderedItems = current.orderedItems else {
                return XCTFail("Unexpectedly found nil Optional")
            }

            // 2 activity items
            XCTAssertEqual(orderedItems.count, 2)

            expect.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testTodaysStats() {
        let expect = expectation(description: "Parse todays stats")
        remoteServiceMock.respondWith = .withDraftAndSchedulePosts

        let blog = newTestBlog(id: wpComID, context: mainContext)

        service.fetch(blog: blog) { cards in
            let todaysStatsItem = cards.first(where: { $0.cardType == .todaysStats })?.normal()

            // Todays stats section exists
            XCTAssertNotNil(todaysStatsItem)

            // Entity has the correct values
            XCTAssertEqual(todaysStatsItem!.apiResponse!.todaysStats!.value!.views, 0)
            XCTAssertEqual(todaysStatsItem!.apiResponse!.todaysStats!.value!.visitors, 0)
            XCTAssertEqual(todaysStatsItem!.apiResponse!.todaysStats!.value!.likes, 0)
            XCTAssertEqual(todaysStatsItem!.apiResponse!.todaysStats!.value!.comments, 0)

            expect.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testHidingCards() {
        // When the stats card is hidden for the current site
        BlogDashboardPersonalizationService(repository: repositoryMock, siteID: wpComID)
            .setEnabled(false, for: .todaysStats)

        let expect = expectation(description: "Parse todays stats")
        remoteServiceMock.respondWith = .withDraftAndSchedulePosts

        let blog = newTestBlog(id: wpComID, context: mainContext)

        service.fetch(blog: blog) { cards in
            // Then it's not displayed
            XCTAssertFalse(cards.contains(where: { $0.cardType == .todaysStats }))
            expect.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testThatWhenAllCardsAreHiddenEmptyStateIsShown() {
        // Given
        let personalizationService = BlogDashboardPersonalizationService(repository: repositoryMock, siteID: wpComID)
        for card in DashboardCard.personalizableCards {
            personalizationService.setEnabled(false, for: card)
        }

        // When
        let expect = expectation(description: "Cards parsed")
        remoteServiceMock.respondWith = .withDraftAndSchedulePosts

        let blog = newTestBlog(id: wpComID, context: mainContext)
        service.fetch(blog: blog) { cards in
            // Then empty state is shown
            XCTAssertEqual(cards.map(\.cardType), [.empty, .personalize])
            expect.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }

    func testThatPreferencesAreSavedPerSite() {
        // When the stats card is hidden for a different site
        BlogDashboardPersonalizationService(repository: repositoryMock, siteID: wpComID + 1)
            .setEnabled(false, for: .todaysStats)

        let expect = expectation(description: "Parse todays stats")
        remoteServiceMock.respondWith = .withDraftAndSchedulePosts

        let blog = newTestBlog(id: wpComID, context: mainContext)

        service.fetch(blog: blog) { cards in
            // Then it's still disabled for other sites
            XCTAssertTrue(cards.contains(where: { $0.cardType == .todaysStats }))
            expect.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testPersistCardsResponse() {
        let expect = expectation(description: "Parse todays stats")
        remoteServiceMock.respondWith = .withDraftAndSchedulePosts

        let blog = newTestBlog(id: wpComID, context: mainContext)

        service.fetch(blog: blog) { snapshot in
            XCTAssertEqual(self.persistenceMock.didCallPersistWithCards,
                           self.dictionary(from: "dashboard-200-with-drafts-and-scheduled.json"))
            XCTAssertEqual(self.persistenceMock.didCallPersistWithWpComID, self.wpComID)

            expect.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testFetchCardsFromPersistence() {
        persistenceMock.respondWith = dictionary(from: "dashboard-200-with-drafts-and-scheduled.json")!

        let blog = newTestBlog(id: wpComID, context: mainContext)

        let cards = service.fetchLocal(blog: blog)

        let hasDrafts = cards.contains(where: {$0.cardType == .draftPosts})
        let hasScheduled = cards.contains(where: {$0.cardType == .scheduledPosts})
        XCTAssertTrue(hasDrafts)
        XCTAssertTrue(hasScheduled)
        XCTAssertEqual(persistenceMock.didCallGetCardsWithWpComID, wpComID)
    }

    // MARK: - Ghost cards

    /// Ghost cards shouldn't be displayed when parsing the API response
    ///
    func testDontReturnGhostCardsWhenFetchingFromTheAPI() {
        let expect = expectation(description: "Parse drafts and scheduled")
        remoteServiceMock.respondWith = .withDraftAndSchedulePosts
        let blog = newTestBlog(id: 10, context: mainContext)

        service.fetch(blog: blog) { cards in
            let hasGhost = cards.contains(where: {$0.cardType == .ghost})
            XCTAssertFalse(hasGhost)

            expect.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    /// Ghost cards shouldn't be displayed when parsing the cached data
    ///
    func testDontReturnGhostCardsWhenFetchingFromCachedData() {
        persistenceMock.respondWith = dictionary(from: "dashboard-200-with-drafts-and-scheduled.json")!
        let blog = newTestBlog(id: 11, context: mainContext)

        let cards = service.fetchLocal(blog: blog)

        let hasGhost = cards.contains(where: {$0.cardType == .ghost})
        XCTAssertFalse(hasGhost)
    }

    /// Ghost cards SHOULD be displayed when there are no cached data
    /// and the response didn't came from the API.
    ///
    func testReturnGhostCardsWhenNoCachedData() {
        persistenceMock.respondWith = nil
        let blog = newTestBlog(id: 12, context: mainContext)

        let cards = service.fetchLocal(blog: blog)

        let ghostCards = cards.filter({$0.cardType == .ghost})
        XCTAssertEqual(ghostCards.count, 1)
    }

    // MARK: - Error card

    /// If the first time load fails, show a failure card
    ///
    func testShowErrorCardWhenFailingToLoad() {
        let expect = expectation(description: "Show error card")
        remoteServiceMock.respondWith = .error
        persistenceMock.respondWith = nil
        let blog = newTestBlog(id: 13, context: mainContext)

        service.fetch(blog: blog) { _ in } failure: { cards in
            let hasError = cards.contains(where: {$0.cardType == .failure})
            XCTAssertTrue(hasError)

            expect.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    /// If the first time load fails, but a subsequent try
    /// succeeds, don't show the failure card
    ///
    func testNotShowErrorCardAfterFailureButThenSuccess() {
        let expect = expectation(description: "Show error card")
        remoteServiceMock.respondWith = .error
        persistenceMock.respondWith = nil
        let blog = newTestBlog(id: 14, context: mainContext)

        /// Call it once and fails
        service.fetch(blog: blog) { _ in } failure: { cards in

            self.remoteServiceMock.respondWith = .withDraftAndSchedulePosts
            /// Call again and succeeds
            self.service.fetch(blog: blog) { cards in
                let hasError = cards.contains(where: {$0.cardType == .failure})
                XCTAssertFalse(hasError)

                expect.fulfill()
            }
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    // MARK: - Local post content

    /// We might run into the case where the API returns that
    /// there are no posts, but the user has local content.
    /// In this case the response is changed to take into account
    /// local content.
    func testReturnPostsCorrectlyBasedOnLocalContent() {
        let expect = expectation(description: "Return local posts")
        remoteServiceMock.respondWith = .withoutPosts
        postsParserMock.hasDraftsAndScheduled = true

        let blog = newTestBlog(id: wpComID, context: mainContext)

        service.fetch(blog: blog) { cards in
            let hasDrafts = cards.contains(where: {$0.cardType == .draftPosts})
            let hasScheduled = cards.contains(where: {$0.cardType == .scheduledPosts})
            XCTAssertTrue(hasDrafts)
            XCTAssertTrue(hasScheduled)

            expect.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    // MARK: - Dynamic Cards

    func testCardsPresenceWhenFeatureFlagIsEnabled() throws {
        let expect = expectation(description: "2 dynamic cards at the top and one at the bottom should be present")
        remoteServiceMock.respondWith = .withMultipleDynamicCards

        let blog = newTestBlog(id: wpComID, context: mainContext)

        service.fetch(blog: blog) { cards in
            XCTAssertEqual(cards[0].dynamic()?.payload.id, "id_12345")
            XCTAssertEqual(cards[1].dynamic()?.payload.id, "id_67890")
            XCTAssertEqual(cards[cards.endIndex - 2].dynamic()?.payload.id, "id_13579")
            expect.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testCardsAbsenceWhenFeatureFlagIsDisabled() throws {
        let expect = expectation(description: "No dynamic card should be present")
        remoteServiceMock.respondWith = .withMultipleDynamicCards
        try featureFlags.override(RemoteFeatureFlag.dynamicDashboardCards, withValue: false)

        let blog = newTestBlog(id: wpComID, context: mainContext)

        service.fetch(blog: blog) { cards in
            let dynamicCards = cards.compactMap { $0.dynamic() }
            XCTAssertTrue(dynamicCards.isEmpty)
            expect.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testDecodingWithDynamicCards() throws {
        let expect = expectation(description: "Dynamic card should be successfully decoded")
        remoteServiceMock.respondWith = .withOnlyOneDynamicCard
        try featureFlags.override(RemoteFeatureFlag.dynamicDashboardCards, withValue: true)

        let blog = newTestBlog(id: wpComID, context: mainContext)

        service.fetch(blog: blog) { cards in
            do {
                let card = try XCTUnwrap(cards.first?.dynamic())
                let payload = card.payload
                let expected = BlogDashboardRemoteEntity.BlogDashboardDynamic(
                    id: "id_12345",
                    title: "Title 12345",
                    featuredImage: "https://example.com/image12345",
                    url: "https://example.com/url12345",
                    action: "Action 12345",
                    order: .top,
                    rows: [
                        .init(
                            title: "Row Title 1",
                            description: nil,
                            icon: "https://example.com/icon12345"
                        ),
                        .init(
                            title: "Row Title 2",
                            description: "Row Description 2",
                            icon: nil
                        )
                    ]
                )
                XCTAssertEqual(payload, expected)
            } catch {
                XCTFail(error.localizedDescription)
            }
            expect.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    // MARK: - Local Pages

    // TODO: Add test to check that local pages are considered if no pages are returned from the endpoint

    func dictionary(from file: String) -> NSDictionary? {
        let fileURL: URL = Bundle(for: BlogDashboardServiceTests.self).url(forResource: file, withExtension: nil)!
        let data: Data = try! Data(contentsOf: fileURL)
        return try? JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary
    }

    private func newTestBlog(id: Int, context: NSManagedObjectContext, isAdmin: Bool = true) -> Blog {
        let blog = ModelTestHelper.insertDotComBlog(context: mainContext)
        blog.account = try! WPAccount.lookupDefaultWordPressComAccount(in: context)
        blog.dotComID = id as NSNumber
        blog.isAdmin = isAdmin
        return blog
    }
}

// MARK: - Mocks

class DashboardServiceRemoteMock: DashboardServiceRemote {
    enum Response: String {
        case withOnlyOneDynamicCard = "dashboard-200-with-only-one-dynamic-card.json"
        case withMultipleDynamicCards = "dashboard-200-with-multiple-dynamic-cards.json"
        case withDraftAndSchedulePosts = "dashboard-200-with-drafts-and-scheduled.json"
        case withDraftsOnly = "dashboard-200-with-drafts-only.json"
        case withoutPosts = "dashboard-200-without-posts.json"
        case error = "error"
    }

    enum Errors: Error {
        case unknown
    }

    var respondWith: Response = .withDraftAndSchedulePosts

    var didCallWithBlogID: Int?
    var didCallWithDeviceId: String?
    var didRequestCards: [String]?

    override func fetch(
        cards: [String],
        forBlogID blogID: Int,
        deviceId: String,
        success: @escaping (NSDictionary) -> Void,
        failure: @escaping (Error) -> Void
    ) {
        didCallWithBlogID = blogID
        didRequestCards = cards
        didCallWithDeviceId = deviceId

        if let fileURL: URL = Bundle(for: BlogDashboardServiceTests.self).url(forResource: respondWith.rawValue, withExtension: nil),
        let data: Data = try? Data(contentsOf: fileURL),
           let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as AnyObject {
            success(jsonObject as! NSDictionary)
        } else {
            failure(Errors.unknown)
        }
    }
}

class BlogDashboardPersistenceMock: BlogDashboardPersistence {
    var didCallPersistWithCards: NSDictionary?
    var didCallPersistWithWpComID: Int?

    override func persist(cards: NSDictionary, for wpComID: Int) {
        didCallPersistWithCards = cards
        didCallPersistWithWpComID = wpComID
    }

    var didCallGetCardsWithWpComID: Int?
    var respondWith: NSDictionary? = [:]

    override func getCards(for wpComID: Int) -> NSDictionary? {
        didCallGetCardsWithWpComID = wpComID

        return respondWith
    }
}

class BlogDashboardPostsParserMock: BlogDashboardPostsParser {
    var hasDraftsAndScheduled = false

    override func parse(_ postsDictionary: NSDictionary, for blog: Blog) -> NSDictionary {
        guard hasDraftsAndScheduled else {
            return postsDictionary
        }

        return ["has_published": false, "draft": [[String: Any]()], "scheduled": [[String: Any]()]]
    }
}
