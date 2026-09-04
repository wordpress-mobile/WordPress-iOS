import Foundation
import Testing

@testable import WordPress
@testable import WordPressData

@Suite("Spotlight identifier decomposition")
struct SearchIdentifierDecompositionTests {
    @Test("a well-formed identifier decomposes")
    func wellFormedIdentifierDecomposes() {
        let parts = SearchIdentifierGenerator.decomposeFromUniqueIdentifier("readerPost|~~~|111|~~~|42")

        #expect(parts?.itemType == .readerPost)
        #expect(parts?.domain == "111")
        #expect(parts?.identifier == "42")
    }

    @Test("malformed identifiers do not decompose")
    func malformedIdentifiersDoNotDecompose() {
        #expect(SearchIdentifierGenerator.decomposeFromUniqueIdentifier("abstractPost|~~~|111") == nil)
        #expect(SearchIdentifierGenerator.decomposeFromUniqueIdentifier("unknown|~~~|111|~~~|42") == nil)
        #expect(SearchIdentifierGenerator.decomposeFromUniqueIdentifier("garbage") == nil)
    }
}

@Suite("Post search identifier parsing")
struct PostSearchIdentifierParsingTests {
    @Test("a post identifier with a numeric domain parses")
    func postIdentifierWithSiteIDParses() {
        let identifier = AbstractPost.SearchIdentifier(identifier: "abstractPost|~~~|111|~~~|42")

        #expect(identifier?.domain == "111")
        #expect(identifier?.postID == 42)
        #expect(identifier?.isDotCom == true)
    }

    @Test("a post identifier with an xmlrpc domain parses")
    func postIdentifierWithXMLRPCDomainParses() {
        let identifier = AbstractPost.SearchIdentifier(
            identifier: "abstractPost|~~~|https://example.com/xmlrpc.php|~~~|7"
        )

        #expect(identifier?.domain == "https://example.com/xmlrpc.php")
        #expect(identifier?.postID == 7)
        #expect(identifier?.isDotCom == false)
    }

    @Test("invalid post identifiers do not parse")
    func invalidPostIdentifiersDoNotParse() {
        #expect(AbstractPost.SearchIdentifier(identifier: "readerPost|~~~|111|~~~|42") == nil)
        #expect(AbstractPost.SearchIdentifier(identifier: "abstractPost|~~~|111|~~~|not-a-number") == nil)
        #expect(AbstractPost.SearchIdentifier(identifier: "abstractPost|~~~|111") == nil)
        #expect(AbstractPost.SearchIdentifier(identifier: "garbage") == nil)
    }
}

@MainActor
@Suite("Post search identifier resolution")
struct PostSearchIdentifierResolutionTests {
    @Test("a WP.com post identifier resolves the matching post")
    func dotComPostResolves() {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).with(dotComID: 111).build()
        let post = PostBuilder(context, blog: blog).published().build()
        post.postID = 42

        #expect(AbstractPost.SearchIdentifier(identifier: "abstractPost|~~~|111|~~~|42")?.post(in: context) == post)
    }

    @Test("a self-hosted post identifier resolves via the xmlrpc domain")
    func selfHostedPostResolves() {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context, dotComID: nil).build()
        blog.xmlrpc = "https://example.com/xmlrpc.php"
        let post = PostBuilder(context, blog: blog).published().build()
        post.postID = 7

        #expect(
            AbstractPost.SearchIdentifier(identifier: "abstractPost|~~~|https://example.com/xmlrpc.php|~~~|7")?
                .post(in: context)
                == post
        )
    }

    @Test("a page identifier resolves the matching page")
    func pageResolves() {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).with(dotComID: 333).build()
        let page = PageBuilder(context).build()
        page.blog = blog
        page.postID = 9

        #expect(AbstractPost.SearchIdentifier(identifier: "abstractPost|~~~|333|~~~|9")?.post(in: context) == page)
    }

    @Test("an identifier for an unknown post resolves nothing")
    func unknownPostResolvesNil() {
        let context = ContextManager.forTesting().mainContext
        BlogBuilder(context).with(dotComID: 111).build()

        #expect(AbstractPost.SearchIdentifier(identifier: "abstractPost|~~~|111|~~~|42")?.post(in: context) == nil)
    }

    @Test("an identifier for an unknown site resolves nothing")
    func unknownSiteResolvesNil() {
        let context = ContextManager.forTesting().mainContext
        let post = PostBuilder(context, blog: BlogBuilder(context).with(dotComID: 111).build()).build()
        post.postID = 42

        #expect(AbstractPost.SearchIdentifier(identifier: "abstractPost|~~~|999|~~~|42")?.post(in: context) == nil)
    }
}
