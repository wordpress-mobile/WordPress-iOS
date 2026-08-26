import OHHTTPStubs
import OHHTTPStubsSwift
import XCTest

@testable import WordPress
@testable import WordPressData

final class WordPressClientFactoryTests: CoreDataTestCase {
    override func setUp() {
        super.setUp()
        contextManager.useAsSharedInstance(untilTestFinished: self)
        WordPressClientFactory.shared.reset()
        HTTPStubs.removeAllStubs()
        stub(condition: { _ in true }) { _ in
            HTTPStubsResponse(
                jsonObject: [:],
                statusCode: 200,
                headers: ["Content-Type": "application/json"]
            )
        }
    }

    override func tearDown() {
        WordPressClientFactory.shared.reset()
        HTTPStubs.removeAllStubs()
        super.tearDown()
    }

    func testEvictInstanceIsIdempotentAndCreatesANewClient() throws {
        let site = try makeSite(dotComID: 123)
        let otherSite = try makeSite(dotComID: 456)
        let original = WordPressClientFactory.shared.instance(for: site)
        let otherOriginal = WordPressClientFactory.shared.instance(for: otherSite)

        WordPressClientFactory.shared.evictInstance(for: site.blogId)
        WordPressClientFactory.shared.evictInstance(for: site.blogId)

        let replacement = WordPressClientFactory.shared.instance(for: site)
        XCTAssertFalse(original === replacement)
        XCTAssertTrue(replacement === WordPressClientFactory.shared.instance(for: site))
        XCTAssertTrue(otherOriginal === WordPressClientFactory.shared.instance(for: otherSite))
    }

    func testResetCreatesANewClient() throws {
        let site = try makeSite(dotComID: 123)
        let original = WordPressClientFactory.shared.instance(for: site)

        WordPressClientFactory.shared.reset()

        XCTAssertFalse(original === WordPressClientFactory.shared.instance(for: site))
    }

    func testRemovingDefaultAccountEvictsBlogClient() throws {
        let blog = makeBlog(dotComID: 123)
        try mainContext.save()
        let site = try WordPressSite(blog: blog)
        let original = WordPressClientFactory.shared.instance(for: site)
        let service = AccountService(coreDataStack: contextManager)
        service.setDefaultWordPressComAccount(try XCTUnwrap(blog.account))

        service.removeDefaultWordPressComAccount()

        XCTAssertFalse(original === WordPressClientFactory.shared.instance(for: site))
    }

    func testRemovingBlogEvictsClient() throws {
        let blog = makeBlog(dotComID: 123)
        try mainContext.save()
        let site = try WordPressSite(blog: blog)
        let original = WordPressClientFactory.shared.instance(for: site)

        BlogService(coreDataStack: contextManager).remove(blog)

        XCTAssertFalse(original === WordPressClientFactory.shared.instance(for: site))
    }

    private func makeSite(dotComID: Int) throws -> WordPressSite {
        try WordPressSite(blog: makeBlog(dotComID: dotComID))
    }

    private func makeBlog(dotComID: Int) -> Blog {
        let blog = BlogBuilder(mainContext, dotComID: NSNumber(value: dotComID))
            .with(url: "https://example.wordpress.com")
            .isHostedAtWPcom()
            .withAnAccount(username: "test-user", authToken: "test-token")
            .build()
        blog.account?.uuid = UUID().uuidString
        return blog
    }
}
