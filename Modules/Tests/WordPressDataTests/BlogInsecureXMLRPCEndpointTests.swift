import CoreData
import Testing
@testable import WordPressData

@MainActor
struct BlogInsecureXMLRPCEndpointTests {
    private let contextManager = ContextManager.forTesting()

    private func makeBlog(url: String?, xmlrpc: String?) -> Blog {
        let blog = BlogBuilder(contextManager.mainContext, dotComID: nil).build()
        blog.account = nil
        blog.url = url
        blog.xmlrpc = xmlrpc
        return blog
    }

    @Test func upgradesHTTPEndpointForHTTPSSite() {
        let blog = makeBlog(url: "https://example.com", xmlrpc: "http://example.com/xmlrpc.php")
        #expect(blog.xmlrpcURL?.absoluteString == "https://example.com/xmlrpc.php")
    }

    @Test func leavesSecureEndpointUnchanged() {
        let blog = makeBlog(url: "https://example.com", xmlrpc: "https://example.com/xmlrpc.php")
        #expect(blog.xmlrpcURL?.absoluteString == "https://example.com/xmlrpc.php")
    }

    @Test func leavesHTTPSiteEndpointUnchanged() {
        // The site itself is http (user-asserted), so the endpoint is left as-is.
        let blog = makeBlog(url: "http://example.com", xmlrpc: "http://example.com/xmlrpc.php")
        #expect(blog.xmlrpcURL?.absoluteString == "http://example.com/xmlrpc.php")
    }

    @Test func returnsNilWhenNoEndpoint() {
        let blog = makeBlog(url: "https://example.com", xmlrpc: nil)
        #expect(blog.xmlrpcURL == nil)
    }

    @Test func upgradesMixedCaseHTTPEndpoint() {
        // URL schemes are case-insensitive, so an uppercase http scheme must still upgrade.
        let blog = makeBlog(url: "https://example.com", xmlrpc: "HTTP://example.com/xmlrpc.php")
        #expect(blog.xmlrpcURL?.scheme == "https")
        #expect(blog.xmlrpcURL?.host == "example.com")
        #expect(blog.xmlrpcURL?.path == "/xmlrpc.php")
    }

    @Test func upgradesForMixedCaseHTTPSSite() {
        let blog = makeBlog(url: "HTTPS://example.com", xmlrpc: "http://example.com/xmlrpc.php")
        #expect(blog.xmlrpcURL?.absoluteString == "https://example.com/xmlrpc.php")
    }

    @Test func rebuildsCachedClientWhenEndpointChanges() throws {
        // Realize the client while the site is http (no upgrade), then flip the site
        // address to https. The cached client must be rebuilt for the upgraded endpoint
        // rather than keep sending to the stale http one.
        let blog = makeBlog(url: "http://example.com", xmlrpc: "http://example.com/xmlrpc.php")
        let httpClient = try #require(blog.xmlrpcApi)

        blog.url = "https://example.com"

        let upgradedClient = try #require(blog.xmlrpcApi)
        #expect(upgradedClient !== httpClient)
    }

    @Test func reusesCachedClientWhenEndpointUnchanged() throws {
        let blog = makeBlog(url: "https://example.com", xmlrpc: "http://example.com/xmlrpc.php")
        let first = try #require(blog.xmlrpcApi)
        let second = try #require(blog.xmlrpcApi)
        #expect(first === second)
    }
}
