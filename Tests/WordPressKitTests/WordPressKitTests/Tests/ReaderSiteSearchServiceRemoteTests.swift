import Foundation
import XCTest
@testable import WordPressKit

class ReaderSiteSearchServiceRemoteTests: RemoteTestCase, RESTTestable {

    // MARK: - Constants

    let performSearchSuccessFilename = "reader-site-search-success.json"
    let performSearchSuccessNoIconFilename = "reader-site-search-success-no-icon.json"
    let performSearchSuccessNoDataFilename = "reader-site-search-success-no-data.json"
    let performSearchSuccessHasMoreFilename = "reader-site-search-success-hasmore.json"
    let performSearchFailureFilename = "reader-site-search-failure.json"
    let performSearchBlogIDFallbackFilename = "reader-site-search-blog-id-fallback.json"
    let performSearchFailsWithNoBlogOrFeedIDFilename = "reader-site-search-no-blog-or-feed-id.json"

    // MARK: - Properties

    var performSearchEndpoint: String { return "read/feed" }

    var remote: ReaderSiteSearchServiceRemote!

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()

        remote = ReaderSiteSearchServiceRemote(wordPressComRestApi: getRestApi())
    }

    override func tearDown() {
        super.tearDown()

        remote = nil
    }

    // MARK: - Perform Search Tests

    func testPerformSearchSuccessfully() {
        let expect = expectation(description: "Perform Reader site search successfully")

        stubRemoteResponse(performSearchEndpoint, filename: performSearchSuccessFilename, contentType: .ApplicationJSON)
        remote.performSearch("discover",
                             count: 10, success: { (feeds, hasMore, totalFeeds) in
                                XCTAssertEqual(feeds.count, 2, "The feed count should be 2")
                                XCTAssertEqual(totalFeeds, 2, "The total feed count should be 2")
                                XCTAssertFalse(hasMore, "The value of hasMore should be false")
                                expect.fulfill()
        }, failure: { _ in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })
        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testPerformSearchWhenResultsHaveNoIcon() {
        let expect = expectation(description: "Perform Reader site search when a result has no icon image value")

        stubRemoteResponse(performSearchEndpoint, filename: performSearchSuccessNoIconFilename, contentType: .ApplicationJSON)
        remote.performSearch("discover",
                             count: 10, success: { (feeds, hasMore, totalFeeds) in
                                XCTAssertEqual(feeds.count, 1, "The feed count should be 1")
                                XCTAssertEqual(totalFeeds, 1, "The total feed count should be 1")
                                XCTAssertFalse(hasMore, "The value of hasMore should be false")

                                guard let feed = feeds.first else {
                                    XCTFail("A feed should be parsed from the JSON")
                                    expect.fulfill()
                                    return
                                }

                                XCTAssertEqual(feed.title, "The Daily Post")
                                XCTAssertEqual(feed.feedID, "27030")
                                XCTAssertEqual(feed.url, URL(string: "https://dailypost.wordpress.com")!)
                                XCTAssertEqual(feed.feedDescription, "The Art and Craft of Blogging")
                                XCTAssertNil(feed.blavatarURL)

                                expect.fulfill()
        }, failure: { _ in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })
        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testPerformSearchWhenResultsHaveNoData() {
        let expect = expectation(description: "Perform Reader site search when a result has no data dictionary")

        stubRemoteResponse(performSearchEndpoint, filename: performSearchSuccessNoDataFilename, contentType: .ApplicationJSON)
        remote.performSearch("discover",
                             count: 10, success: { (feeds, hasMore, totalFeeds) in
                                XCTAssertEqual(feeds.count, 1, "The feed count should be 1")
                                XCTAssertEqual(totalFeeds, 1, "The total feed count should be 1")
                                XCTAssertFalse(hasMore, "The value of hasMore should be false")

                                guard let feed = feeds.first else {
                                    XCTFail("A feed should be parsed from the JSON")
                                    expect.fulfill()
                                    return
                                }

                                XCTAssertEqual(feed.title, "The Daily Post")
                                XCTAssertEqual(feed.feedID, "27030")
                                XCTAssertEqual(feed.url, URL(string: "https://dailypost.wordpress.com")!)
                                XCTAssertNil(feed.blavatarURL)
                                XCTAssertNil(feed.feedDescription)

                                expect.fulfill()

        }, failure: { _ in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })
        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testPerformSearchHasMoreResults() {
        let expect = expectation(description: "Perform Reader site search successfully and reports hasMore correctly")

        stubRemoteResponse(performSearchEndpoint, filename: performSearchSuccessHasMoreFilename, contentType: .ApplicationJSON)
        remote.performSearch("discover",
                             count: 2, success: { (feeds, hasMore, totalFeeds) in
                                XCTAssertEqual(feeds.count, 2, "The feed count should be 2")
                                XCTAssertEqual(totalFeeds, 3, "The total feed count should be 3")
                                XCTAssertTrue(hasMore, "The value of hasMore should be true")
                                expect.fulfill()
        }, failure: { _ in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })
        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testPerformSearchHasMoreResultsEqualCount() {
        let expect = expectation(description: "Perform Reader site search successfully and reports hasMore correctly when the page size equals the feed count")

        stubRemoteResponse(performSearchEndpoint, filename: performSearchSuccessFilename, contentType: .ApplicationJSON)
        remote.performSearch("discover",
                             count: 2, success: { (feeds, hasMore, totalFeeds) in
                                XCTAssertEqual(feeds.count, 2, "The feed count should be 2")
                                XCTAssertEqual(totalFeeds, 2, "The total feed count should be 2")
                                XCTAssertFalse(hasMore, "The value of hasMore should be false")
                                expect.fulfill()
        }, failure: { _ in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })
        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testPerformSearchFailure() {
        let expect = expectation(description: "Perform Reader site search fails if no URL is present")

        stubRemoteResponse(performSearchEndpoint, filename: performSearchFailureFilename, contentType: .ApplicationJSON)
        remote.performSearch("discover",
                             count: 10, success: { (_, _, _) in
                                XCTFail("This callback shouldn't get called")
                                expect.fulfill()
        }, failure: { error in
            typealias ResponseError = ReaderSiteSearchServiceRemote.ResponseError
            guard case ResponseError.decodingFailure? = error as? ResponseError else {
                XCTFail("Expected a decodingFailure error")
                expect.fulfill()
                return
            }

            expect.fulfill()
        })
        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testPerformSearchBlogIDFallback() {
        let expect = expectation(description: "Perform Reader site search falls back to parsing blog ID if no feed ID is present")

        stubRemoteResponse(performSearchEndpoint, filename: performSearchBlogIDFallbackFilename, contentType: .ApplicationJSON)
        remote.performSearch("discover",
                             count: 10, success: { (feeds, hasMore, totalFeeds) in
                                XCTAssertEqual(feeds.count, 1, "The feed count should be 1")
                                XCTAssertEqual(totalFeeds, 1, "The total feed count should be 1")
                                XCTAssertFalse(hasMore, "The value of hasMore should be false")

                                guard let feed = feeds.first else {
                                    XCTFail("A feed should be parsed from the JSON")
                                    expect.fulfill()
                                    return
                                }

                                XCTAssertEqual(feed.title, "The Daily Post")
                                XCTAssertNil(feed.feedID)
                                XCTAssertEqual(feed.blogID, "489937")
                                XCTAssertEqual(feed.url, URL(string: "https://dailypost.wordpress.com")!)
                                XCTAssertEqual(feed.feedDescription, "The Art and Craft of Blogging")

                                expect.fulfill()
        }, failure: { _ in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })
        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testPerformSearchOmitsFeedsWithNoBlogOrFeedID() {
        let expect = expectation(description: "Perform Reader site search omits feeds that have no blog ID or feed ID")

        stubRemoteResponse(performSearchEndpoint, filename: performSearchFailsWithNoBlogOrFeedIDFilename, contentType: .ApplicationJSON)
        remote.performSearch("discover",
                             count: 10, success: { (feeds, hasMore, totalFeeds) in
                                XCTAssertEqual(feeds.count, 1, "The feed count should be 1")
                                XCTAssertEqual(totalFeeds, 2, "The total feed count should be 2")   // one feed filtered out
                                XCTAssertFalse(hasMore, "The value of hasMore should be false")

                                guard let feed = feeds.first else {
                                    XCTFail("A feed should be parsed from the JSON")
                                    expect.fulfill()
                                    return
                                }

                                XCTAssertEqual(feed.title, "Discover")
                                XCTAssertEqual(feed.feedID, "41325786")
                                XCTAssertEqual(feed.url, URL(string: "https://discover.wordpress.com")!)
                                XCTAssertEqual(feed.feedDescription, "A daily selection of the best content published on WordPress, collected for you by humans who love to read.")

                                expect.fulfill()
        }, failure: { _ in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })
        waitForExpectations(timeout: timeout, handler: nil)
    }
}
