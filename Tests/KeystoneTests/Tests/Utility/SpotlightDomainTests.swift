import CoreSpotlight
import Testing
@testable import WordPress
@testable import WordPressData

@MainActor
@Suite("Spotlight domains")
struct SpotlightDomainTests {
    private let context = ContextManager.forTesting().mainContext

    /// Scenario: the user removes a site they also read in the Reader.
    @Test("Reader items are indexed outside the site's domain")
    func readerItemsUseTheirOwnDomain() throws {
        // GIVEN a site's post and a Reader post from the same site
        let blog = BlogBuilder(context, dotComID: 80511).build()
        let post = PostBuilder(context, blog: blog).build()
        post.postID = 974
        post.postTitle = "Site post"
        let readerPost = ReaderPostBuilder(context).build()
        readerPost.siteID = 80511
        readerPost.postID = 975
        readerPost.postTitle = "Reader post"

        // WHEN they are indexed
        let postItem = try #require(post.indexableItem())
        let readerItem = try #require(readerPost.indexableItem())

        // THEN site removal, which deletes the site's domain, doesn't include the Reader item
        #expect(postItem.domainIdentifier == "80511")
        #expect(readerItem.domainIdentifier == "reader.80511")

        // THEN the unique identifier that tap handling decodes keeps the site ID
        #expect(readerItem.uniqueIdentifier == "readerPost|~~~|80511|~~~|975")
    }

    /// Scenario: a self-hosted site connects Jetpack after its posts were
    /// indexed, then the user removes the site.
    @Test("Site removal covers items indexed before Jetpack connected")
    func siteDomainsIncludeTheXMLRPCAddress() {
        // GIVEN a self-hosted site whose posts are indexed under its XML-RPC address
        let site = BlogBuilder(context, dotComID: nil).with(url: "https://example.com").build()
        site.xmlrpc = "https://example.com/xmlrpc.php"
        #expect(site.searchDomain == "https://example.com/xmlrpc.php")

        // WHEN the site gets a site ID
        site.dotComID = 777

        // THEN site removal targets both the new domain and the one the posts were indexed under
        #expect(site.searchDomain == "777")
        #expect(site.searchDomains == ["777", "https://example.com/xmlrpc.php"])
    }

    @Test("A site without an XML-RPC address has only its site ID domain")
    func siteDomainsWithoutXMLRPCAddress() {
        let site = BlogBuilder(context, dotComID: 80511).build()
        site.xmlrpc = nil

        #expect(site.searchDomains == ["80511"])
    }
}
