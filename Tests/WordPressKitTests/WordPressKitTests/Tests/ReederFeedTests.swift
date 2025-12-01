import Foundation
import Testing

@testable import WordPressKit

struct ReaderFeedTests {

    // MARK: - Jetpack-connected Sites

    /// Tests decoding a Jetpack-connected WordPress site feed where URL, title, and description
    /// must fall back to meta.data.feed fields since they're not present at root level.
    @Test func decodesJetpackConnectedSiteFeed() throws {
        // GIVEN: Search response for a Jetpack site (ma.tt)
        let jsonData = try loadMockJSON(filename: "reader-search-response-01")

        // WHEN: Decoding the envelope
        let decoder = JSONDecoder()
        let envelope = try decoder.decode(ReaderFeedEnvelope.self, from: jsonData)

        // THEN: Envelope contains one feed with no total count
        #expect(envelope.feeds.count == 1)
        #expect(envelope.total == nil)

        let feed = try #require(envelope.feeds.first)

        // THEN: IDs are decoded correctly
        #expect(feed.feedID == "188407")
        #expect(feed.blogID == "1047865")

        // THEN: Feed metadata falls back to meta.data.feed fields
        #expect(feed.url?.absoluteString == "https://ma.tt")
        #expect(feed.title == "Matt Mullenweg")
        #expect(feed.description == "Unlucky in Cards")
        #expect(feed.iconURL?.absoluteString == "https://ma.tt/files/2024/01/cropped-matt-favicon.png")
    }

    // MARK: - WordPress.com Sites

    /// Tests decoding a WordPress.com site feed where URL and title are present at root level,
    /// and the envelope includes a total count field.
    @Test func decodesWordPressComSiteFeed() throws {
        // GIVEN: Search response for a WordPress.com site (veselin.blog)
        let jsonData = try loadMockJSON(filename: "reader-search-response-02")

        // WHEN: Decoding the envelope
        let decoder = JSONDecoder()
        let envelope = try decoder.decode(ReaderFeedEnvelope.self, from: jsonData)

        // THEN: Envelope contains one feed with total count
        #expect(envelope.feeds.count == 1)
        #expect(envelope.total == 1)

        let feed = try #require(envelope.feeds.first)

        // THEN: IDs are decoded from root level
        #expect(feed.feedID == "152023972")
        #expect(feed.blogID == "125098293")

        // THEN: URL and title are at root level
        #expect(feed.url?.absoluteString == "http://veselin.blog")
        #expect(feed.title == "Veselin.blog")

        // THEN: Description and icon fall back to meta.data fields
        #expect(feed.description == "Cats, good books, AI, and religious walking in the city of Sofia")
        #expect(feed.iconURL?.absoluteString == "https://veselinblogblog.wordpress.com/wp-content/uploads/2024/04/cropped-avatar-18.jpg?w=96")
    }

    // MARK: - External RSS Feeds

    /// Tests decoding an external RSS feed (not a WordPress site) where blogID is "0"
    /// and only feed metadata is available (no site data).
    @Test func decodesExternalRSSFeed() throws {
        // GIVEN: Search response for an external RSS feed (Daring Fireball)
        let jsonData = try loadMockJSON(filename: "reader-search-response-03")

        // WHEN: Decoding the envelope
        let decoder = JSONDecoder()
        let envelope = try decoder.decode(ReaderFeedEnvelope.self, from: jsonData)

        // THEN: Envelope contains one feed with no total count
        #expect(envelope.feeds.count == 1)
        #expect(envelope.total == nil)

        let feed = try #require(envelope.feeds.first)

        // THEN: Feed ID is present but blog ID is "0" for external RSS feeds
        #expect(feed.feedID == "20787116")
        #expect(feed.blogID == nil)

        // THEN: Feed metadata falls back to meta.data.feed fields
        #expect(feed.url?.absoluteString == "https://daringfireball.net/")
        #expect(feed.title == "Daring Fireball")
        #expect(feed.description == "By John Gruber")

        // THEN: No icon available for this external RSS feed
        #expect(feed.iconURL == nil)
    }

    // MARK: - Helpers

    private func loadMockJSON(filename: String) throws -> Data {
        // Use the test bundle by referencing a class from the test target
        let bundle = Bundle(for: RemoteTestCase.self)
        guard let url = bundle.url(forResource: filename, withExtension: "json") else {
            throw NSError(domain: "ReaderFeedTests", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock file not found: \(filename).json"])
        }
        return try Data(contentsOf: url)
    }
}
