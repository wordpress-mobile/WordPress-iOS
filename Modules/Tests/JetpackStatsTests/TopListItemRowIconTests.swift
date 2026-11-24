import Foundation
import Testing
@preconcurrency import WordPressKit
@testable import JetpackStats

/// Covers the data a Posts & Pages or Clicks row needs to draw its leading icon.
@Suite
struct TopListItemRowIconTests {
    @Test(
        "Reads the ID the site's posts endpoint knows a post by",
        arguments: [
            ("1234", 1234),
            // Stats reports the homepage with an ID of 0; it has no featured image of
            // its own, so there is nothing to look up.
            ("0", nil),
            ("not-a-number", nil),
            (nil, nil)
        ] as [(String?, Int?)]
    )
    func numericPostID(postID: String?, expected: Int?) {
        #expect(makePost(postID: postID).numericPostID == expected)
    }

    @Test(
        "Gives the post glyph only to a post, and the page glyph to everything else",
        arguments: [
            ("post", "text.page"),
            ("POST", "text.page"),
            ("page", "doc"),
            ("homepage", "doc"),
            ("unknown", "doc"),
            (nil, "doc")
        ] as [(String?, String)]
    )
    func typeSystemImage(type: String?, expected: String) {
        #expect(makePost(type: type).typeSystemImage == expected)
    }

    @Test("Keeps the icon the stats API reports for a clicked link")
    func mapsClickIconURL() throws {
        let iconURL = try #require(URL(string: "https://example.com/favicon.ico"))
        let click = StatsClick(
            title: "Example",
            clicksCount: 1,
            clickedURL: URL(string: "https://example.com"),
            iconURL: iconURL,
            children: [
                StatsClick(
                    title: "Example page",
                    clicksCount: 1,
                    clickedURL: URL(string: "https://example.com/page"),
                    iconURL: nil,
                    children: []
                )
            ]
        )

        let link = TopListItem.ExternalLink(click)

        #expect(link.iconURL == iconURL)
        #expect(link.children.first?.iconURL == nil)
    }

    private func makePost(postID: String? = "1", type: String? = nil) -> TopListItem.Post {
        TopListItem.Post(
            title: "Example",
            postID: postID,
            postURL: nil,
            date: nil,
            type: type,
            author: nil,
            metrics: SiteMetricsSet()
        )
    }
}
