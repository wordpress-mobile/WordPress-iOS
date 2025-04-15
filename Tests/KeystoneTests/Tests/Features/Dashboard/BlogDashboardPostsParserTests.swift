import XCTest

@testable import WordPress

class BlogDashboardPostsParserTests: CoreDataTestCase {

    private var parser: BlogDashboardPostsParser!

    override func setUp() {
        super.setUp()

        parser = BlogDashboardPostsParser(managedObjectContext: mainContext)
    }

    /// When the API return no drafts, but there are local drafts
    /// Return one local draft
    func testReturnLocalDraftWhenItExists() {
        let blog = BlogBuilder(mainContext).build()
        _ = PostBuilder(mainContext, blog: blog).drafted().build()

        let postsWithLocalContent = parser.parse(cardsResponseWithoutPosts["posts"] as! NSDictionary,
                                                 for: blog)

        XCTAssertEqual((postsWithLocalContent["draft"] as? [Any])?.count, 1)
    }

    /// When the API return no drafts, and there are no local drafts
    /// Return zero drafts
    func testReturnZeroDraftsWhenNothingLocal() {
        let blog = BlogBuilder(mainContext).build()

        let postsWithLocalContent = parser.parse(cardsResponseWithoutPosts["posts"] as! NSDictionary,
                                                 for: blog)

        XCTAssertEqual((postsWithLocalContent["draft"] as? [Any])?.count, 0)
    }

    /// When the API return drafts, keep the amount returned
    func testReturnDraftsTrimmedEvenWithZeroLocalDrafts() {
        let blog = BlogBuilder(mainContext).build()

        let postsWithLocalContent = parser.parse(cardsResponseWithPosts["posts"] as! NSDictionary,
                                                 for: blog)

        XCTAssertEqual((postsWithLocalContent["draft"] as? [Any])?.count, 1)
    }

    /// When the API return no scheduled, but there are local scheduled posts
    /// Return one scheduled post
    func testReturnLocalScheduledWhenItExists() {
        let blog = BlogBuilder(mainContext).build()
        _ = PostBuilder(mainContext, blog: blog).scheduled().withRemote().build()

        let postsWithLocalContent = parser.parse(cardsResponseWithoutPosts["posts"] as! NSDictionary,
                                                 for: blog)

        XCTAssertEqual((postsWithLocalContent["scheduled"] as? [Any])?.count, 1)
    }

    /// When the API return no scheduled, and there are no
    /// local scheduled posts, return zero scheduled posts
    func testReturnZeroScheduledWhenNothingLocal() {
        let blog = BlogBuilder(mainContext).build()

        let postsWithLocalContent = parser.parse(cardsResponseWithoutPosts["posts"] as! NSDictionary,
                                                 for: blog)

        XCTAssertEqual((postsWithLocalContent["scheduled"] as? [Any])?.count, 0)
    }

    /// When the API return scheduled posts, keep the amount returned
    func testReturnScheduledAsItIsEvenWhenLocalScheduledExists() {
        let blog = BlogBuilder(mainContext).build()
        _ = PostBuilder(mainContext, blog: blog).scheduled().withRemote().build()

        let postsWithLocalContent = parser.parse(cardsResponseWithPosts["posts"] as! NSDictionary,
                                                 for: blog)

        XCTAssertEqual((postsWithLocalContent["scheduled"] as? [Any])?.count, 1)
    }
}

private extension BlogDashboardPostsParserTests {
    var cardsResponseWithoutPosts: NSDictionary {
        let fileURL: URL = Bundle(for: BlogDashboardPersistenceTests.self).url(forResource: "dashboard-200-without-posts.json", withExtension: nil)!
        let data: Data = try! Data(contentsOf: fileURL)
        return try! JSONSerialization.jsonObject(with: data, options: []) as! NSDictionary
    }

    var cardsResponseWithPosts: NSDictionary {
        let fileURL: URL = Bundle(for: BlogDashboardPersistenceTests.self).url(forResource: "dashboard-200-with-drafts-and-scheduled.json", withExtension: nil)!
        let data: Data = try! Data(contentsOf: fileURL)
        return try! JSONSerialization.jsonObject(with: data, options: []) as! NSDictionary
    }
}
