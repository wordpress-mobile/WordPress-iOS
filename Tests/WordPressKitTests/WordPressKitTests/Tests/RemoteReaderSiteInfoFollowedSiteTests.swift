import Foundation
import Testing
@testable import WordPressKit

struct RemoteReaderSiteInfoFollowedSiteTests {

    /// Entries from `read/following/mine?meta=site,feed`, in fixture order:
    /// a site with site meta, a feed whose meta is an error object, a feed whose meta has
    /// no name and no URL, and a feed subscribed moments ago with an empty `name`.
    private let entries: [NSDictionary]

    init() throws {
        let response = try #require(JSONLoader().loadFile("reader-following-mine-incomplete-meta", type: "json"))
        entries = try #require(response["subscriptions"] as? [NSDictionary])
    }

    @Test func siteMetaIsPreferred() {
        let siteInfo = RemoteReaderSiteInfo.siteInfo(forFollowedSiteResponse: entries[0])

        #expect(siteInfo.siteID == 257970269)
        #expect(siteInfo.feedID == 182552112)
        #expect(siteInfo.siteName == "testgallary")
        #expect(siteInfo.siteURL == "https://testgallary.wordpress.com")
        #expect(siteInfo.endpointPath == "read/sites/257970269/posts/")
        #expect(siteInfo.isFollowing)
    }

    @Test func feedMetaErrorFallsBackToEntryFields() {
        let siteInfo = RemoteReaderSiteInfo.siteInfo(forFollowedSiteResponse: entries[1])

        #expect(siteInfo.feedID == 182647174)
        #expect(siteInfo.feedURL == "http://tremendously-random.jurassic.ninja/feed")
        #expect(siteInfo.siteName == "Tremendously Random")
        #expect(siteInfo.siteURL == "http://tremendously-random.jurassic.ninja")
        #expect(siteInfo.endpointPath == "read/feed/182647174/posts/")
        #expect(siteInfo.isFollowing)
    }

    @Test func emptyFeedMetaUsesEntryNameAndURL() {
        let siteInfo = RemoteReaderSiteInfo.siteInfo(forFollowedSiteResponse: entries[2])

        #expect(siteInfo.feedID == 175735670)
        #expect(siteInfo.siteName == "Impressed Grizzly")
        #expect(siteInfo.siteURL == "http://impressed-grizzly.jurassic.ninja")
        #expect(siteInfo.endpointPath == "read/feed/175735670/posts/")
        #expect(siteInfo.isFollowing)
    }

    @Test func emptyNameFallsBackToHost() {
        let siteInfo = RemoteReaderSiteInfo.siteInfo(forFollowedSiteResponse: entries[3])

        #expect(siteInfo.feedID == 182815000)
        #expect(siteInfo.siteName == "www.raspberrypi.com")
        #expect(siteInfo.siteURL == "http://www.raspberrypi.com/news")
        #expect(siteInfo.endpointPath == "read/feed/182815000/posts/")
    }

    @Test func siteMetaErrorKeepsSiteEndpoint() {
        let error: NSDictionary = ["errors": ["unauthorized": ["User cannot access this private blog."]]]
        let entry: NSDictionary = [
            "blog_ID": "1001",
            "feed_ID": "2002",
            "URL": "https://private-site.example.com",
            "feed_URL": "https://private-site.example.com/feed",
            "name": "Private Site",
            "meta": ["data": ["site": error, "feed": error]]
        ]

        let siteInfo = RemoteReaderSiteInfo.siteInfo(forFollowedSiteResponse: entry)

        #expect(siteInfo.siteID == 1001)
        #expect(siteInfo.feedID == 2002)
        #expect(siteInfo.siteName == "Private Site")
        #expect(siteInfo.endpointPath == "read/sites/1001/posts/")
        #expect(siteInfo.isFollowing)
    }
}
