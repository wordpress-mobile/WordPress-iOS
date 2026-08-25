import Foundation
import Testing
@preconcurrency import WordPressKit
@testable import JetpackStats

@Suite
struct TopListItemReferrerTests {
    struct TestCase: Sendable {
        let name: String
        let domain: String?
        let url: URL?
        let expectedValue: Bool
    }

    @Test(
        "Determines whether a referrer can be marked as spam",
        arguments: [
            TestCase(
                name: "example.com",
                domain: "example.com",
                url: URL(string: "https://example.com/path"),
                expectedValue: true
            ),
            TestCase(
                name: "WordPress.com Reader",
                domain: "wordpress.com",
                url: URL(string: "https://wordpress.com/read"),
                expectedValue: false
            ),
            TestCase(name: "example.com", domain: "example.com", url: nil, expectedValue: true),
            TestCase(name: "example.com", domain: nil, url: nil, expectedValue: false),
            TestCase(name: "Example", domain: nil, url: nil, expectedValue: false)
        ]
    )
    func canMarkAsSpam(testCase: TestCase) {
        let referrer = TopListItem.Referrer(
            name: testCase.name,
            domain: testCase.domain,
            url: testCase.url,
            iconURL: nil,
            children: [],
            metrics: SiteMetricsSet()
        )

        #expect(referrer.canMarkAsSpam == testCase.expectedValue)
    }

    @Test("Uses a child domain when a grouped referrer has no domain")
    func usesChildDomain() {
        let child = makeReferrer(name: "example.com", domain: "example.com")
        let referrer = makeReferrer(name: "example.com", children: [child])

        #expect(referrer.spamDomain == "example.com")
        #expect(referrer.canMarkAsSpam)
    }

    @Test("Decodes referrer data cached before the source URL was added")
    func decodesReferrerWithoutURL() throws {
        let referrer = makeReferrer(name: "example.com", domain: "example.com")
        var object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(referrer)) as? [String: Any])
        object.removeValue(forKey: "url")

        let data = try JSONSerialization.data(withJSONObject: object)
        let decoded = try JSONDecoder().decode(TopListItem.Referrer.self, from: data)

        #expect(decoded.url == nil)
    }

    @Test("Preserves the source URL when mapping a WordPressKit referrer")
    func mapsSourceURL() throws {
        let sourceURL = try #require(URL(string: "https://example.com/path"))
        let referrer = StatsReferrer(
            title: "example.com",
            viewsCount: 1,
            url: sourceURL,
            iconURL: nil,
            children: []
        )

        #expect(TopListItem.Referrer(referrer).url == sourceURL)
    }

    private func makeReferrer(
        name: String,
        domain: String? = nil,
        children: [TopListItem.Referrer] = []
    ) -> TopListItem.Referrer {
        TopListItem.Referrer(
            name: name,
            domain: domain,
            url: nil,
            iconURL: nil,
            children: children,
            metrics: SiteMetricsSet()
        )
    }
}
