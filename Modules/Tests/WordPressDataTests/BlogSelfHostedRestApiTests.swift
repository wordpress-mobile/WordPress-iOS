import CoreData
import Testing
@testable import WordPressData

@MainActor
struct BlogSelfHostedRestApiTests {
    private let contextManager = ContextManager.forTesting()

    private func makeBlog(url: String?, xmlrpc: String?, restApiRootURL: String?) -> Blog {
        let blog = BlogBuilder(contextManager.mainContext, dotComID: nil).build()
        blog.account = nil
        blog.url = url
        blog.xmlrpc = xmlrpc
        blog.restApiRootURL = restApiRootURL
        return blog
    }

    @Test func prefersDiscoveredHTTPSRootOverDowngradedXMLRPCEndpoint() {
        // An older app version could persist an http xmlrpc endpoint for an https site; the
        // https REST root observed during discovery must win so the application password is
        // never sent over plaintext http.
        let blog = makeBlog(
            url: "https://example.com",
            xmlrpc: "http://example.com/xmlrpc.php",
            restApiRootURL: "https://example.com/wp-json/"
        )
        #expect(blog.selfHostedRestApiRootURL?.absoluteString == "https://example.com/wp-json/")
    }

    @Test func fallsBackToXMLRPCDerivedRootWhenNoDiscoveredRoot() {
        // Legacy XML-RPC sign-ins never persisted a REST root, so behavior is unchanged.
        let blog = makeBlog(
            url: "https://example.com",
            xmlrpc: "https://example.com/xmlrpc.php",
            restApiRootURL: nil
        )
        #expect(blog.selfHostedRestApiRootURL?.absoluteString == "https://example.com/wp-json/")
    }

    @Test func returnsNilWhenNeitherRootIsAvailable() {
        let blog = makeBlog(url: "https://example.com", xmlrpc: nil, restApiRootURL: nil)
        #expect(blog.selfHostedRestApiRootURL == nil)
    }
}
