import Foundation
import Testing

@testable import WordPress
@testable import WordPressData

@Suite("App Intent identifier parsing")
struct AppIntentIdentifierParsingTests {
    @Test("a post identifier with a numeric domain parses")
    func postIdentifierWithSiteIDParses() {
        let identifier = AbstractPost.AppIntentIdentifier(identifier: "abstractPost|~~~|111|~~~|42")

        #expect(identifier?.domain == "111")
        #expect(identifier?.postID == 42)
    }

    @Test("a post identifier with an xmlrpc domain parses")
    func postIdentifierWithXMLRPCDomainParses() {
        let identifier = AbstractPost.AppIntentIdentifier(
            identifier: "abstractPost|~~~|https://example.com/xmlrpc.php|~~~|7"
        )

        #expect(identifier?.domain == "https://example.com/xmlrpc.php")
        #expect(identifier?.postID == 7)
    }

    @Test("invalid post identifiers do not parse")
    func invalidPostIdentifiersDoNotParse() {
        #expect(AbstractPost.AppIntentIdentifier(identifier: "readerPost|~~~|111|~~~|42") == nil)
        #expect(AbstractPost.AppIntentIdentifier(identifier: "abstractPost|~~~|111|~~~|not-a-number") == nil)
        #expect(AbstractPost.AppIntentIdentifier(identifier: "abstractPost|~~~|111") == nil)
        #expect(AbstractPost.AppIntentIdentifier(identifier: "garbage") == nil)
    }

    @Test("a reader post identifier parses")
    func readerPostIdentifierParses() {
        let identifier = ReaderPost.AppIntentIdentifier(identifier: "readerPost|~~~|111|~~~|42")

        #expect(identifier?.siteID == 111)
        #expect(identifier?.postID == 42)
    }

    @Test("invalid reader post identifiers do not parse")
    func invalidReaderPostIdentifiersDoNotParse() {
        #expect(ReaderPost.AppIntentIdentifier(identifier: "abstractPost|~~~|111|~~~|42") == nil)
        #expect(ReaderPost.AppIntentIdentifier(identifier: "readerPost|~~~|example.com|~~~|42") == nil)
        #expect(ReaderPost.AppIntentIdentifier(identifier: "readerPost|~~~|111|~~~|not-a-number") == nil)
        #expect(ReaderPost.AppIntentIdentifier(identifier: "garbage") == nil)
    }
}

@MainActor
@Suite("Post app intent resolution")
struct PostAppIntentResolutionTests {
    @Test("a WP.com post identifier resolves the matching post")
    func dotComPostResolves() {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).with(dotComID: 111).build()
        let post = PostBuilder(context, blog: blog).published().build()
        post.postID = 42

        #expect(AbstractPost.forAppIntent(identifier: "abstractPost|~~~|111|~~~|42", in: context) == post)
    }

    @Test("a self-hosted post identifier resolves via the xmlrpc domain")
    func selfHostedPostResolves() {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context, dotComID: nil).build()
        blog.xmlrpc = "https://example.com/xmlrpc.php"
        let post = PostBuilder(context, blog: blog).published().build()
        post.postID = 7

        #expect(
            AbstractPost.forAppIntent(identifier: "abstractPost|~~~|https://example.com/xmlrpc.php|~~~|7", in: context)
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

        #expect(AbstractPost.forAppIntent(identifier: "abstractPost|~~~|333|~~~|9", in: context) == page)
    }

    @Test("a trashed post identifier resolves nothing")
    func trashedPostResolvesNil() {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).with(dotComID: 111).build()
        let post = PostBuilder(context, blog: blog).trashed().build()
        post.postID = 42

        #expect(AbstractPost.forAppIntent(identifier: "abstractPost|~~~|111|~~~|42", in: context) == nil)
    }

    @Test("an identifier for an unknown post resolves nothing")
    func unknownPostResolvesNil() {
        let context = ContextManager.forTesting().mainContext
        BlogBuilder(context).with(dotComID: 111).build()

        #expect(AbstractPost.forAppIntent(identifier: "abstractPost|~~~|111|~~~|42", in: context) == nil)
    }

    @Test("an identifier for an unknown site resolves nothing")
    func unknownSiteResolvesNil() {
        let context = ContextManager.forTesting().mainContext
        let post = PostBuilder(context, blog: BlogBuilder(context).with(dotComID: 111).build()).build()
        post.postID = 42

        #expect(AbstractPost.forAppIntent(identifier: "abstractPost|~~~|999|~~~|42", in: context) == nil)
    }

    @Test("a reader post identifier resolves the matching reader post")
    func readerPostResolves() {
        let context = ContextManager.forTesting().mainContext
        let post = ReaderPostBuilder(context).build()
        post.postID = 42
        post.siteID = 111

        #expect(ReaderPost.forAppIntent(identifier: "readerPost|~~~|111|~~~|42", in: context) == post)
    }

    @Test("a reader post identifier with IDs beyond Int32 resolves the matching reader post")
    func readerPostWithLargeIDsResolves() {
        let context = ContextManager.forTesting().mainContext
        let post = ReaderPostBuilder(context).build()
        post.postID = NSNumber(value: 10_000_000_000)
        post.siteID = NSNumber(value: 3_000_000_000)

        #expect(ReaderPost.forAppIntent(identifier: "readerPost|~~~|3000000000|~~~|10000000000", in: context) == post)
    }

    @Test("an identifier for an unknown reader post resolves nothing")
    func unknownReaderPostResolvesNil() {
        let context = ContextManager.forTesting().mainContext
        let post = ReaderPostBuilder(context).build()
        post.postID = 42
        post.siteID = 111

        #expect(ReaderPost.forAppIntent(identifier: "readerPost|~~~|111|~~~|43", in: context) == nil)
    }
}

@MainActor
@Suite("Post app intent search")
struct PostAppIntentSearchTests {
    @Test("matches posts and pages by title, case-insensitively")
    func matchesByTitle() {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).with(dotComID: 111).build()
        let post = PostBuilder(context, blog: blog).published().with(title: "Hello World").build()
        post.postID = 1
        let page = PageBuilder(context).build()
        page.blog = blog
        page.postTitle = "world tour"
        page.postID = 2
        let other = PostBuilder(context, blog: blog).published().with(title: "Something else").build()
        other.postID = 3

        let results = AbstractPost.searchForAppIntent(matching: "world", in: context)

        #expect(Set(results) == Set([post, page]))
    }

    @Test("excludes trashed posts, local-only posts, and revisions")
    func excludesUnsearchablePosts() {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).with(dotComID: 111).build()
        let match = PostBuilder(context, blog: blog).published().with(title: "Match A").build()
        match.postID = 1
        _ = match.createRevision()
        let trashed = PostBuilder(context, blog: blog).trashed().with(title: "Match B").build()
        trashed.postID = 2
        PostBuilder(context, blog: blog).drafted().with(title: "Match C, local only").build()

        let results = AbstractPost.searchForAppIntent(matching: "match", in: context)

        #expect(results == [match])
    }

    @Test("an empty query returns recent posts, most recently modified first")
    func emptyQueryReturnsRecentPosts() {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).with(dotComID: 111).build()
        let older = PostBuilder(context, blog: blog).published().with(title: "Older")
            .with(dateModified: Date(timeIntervalSince1970: 1000)).build()
        older.postID = 1
        let newer = PostBuilder(context, blog: blog).published().with(title: "Newer")
            .with(dateModified: Date(timeIntervalSince1970: 2000)).build()
        newer.postID = 2

        let results = AbstractPost.searchForAppIntent(matching: "", in: context)

        #expect(results == [newer, older])
    }

    @Test("caps the number of results")
    func capsResults() {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).with(dotComID: 111).build()
        for index in 1...3 {
            let post = PostBuilder(context, blog: blog).published().with(title: "Post \(index)").build()
            post.postID = NSNumber(value: index)
        }

        let results = AbstractPost.searchForAppIntent(matching: "", limit: 2, in: context)

        #expect(results.count == 2)
    }

    @Test("matches reader posts by title")
    func matchesReaderPostsByTitle() {
        let context = ContextManager.forTesting().mainContext
        let match = ReaderPostBuilder(context).build()
        match.postTitle = "Hello World"
        match.postID = 1
        match.siteID = 9
        let other = ReaderPostBuilder(context).build()
        other.postTitle = "Something else"
        other.postID = 2
        other.siteID = 9

        let results = ReaderPost.searchForAppIntent(matching: "world", in: context)

        #expect(results == [match])
    }

    @Test("an empty query returns recent reader posts, newest first")
    func emptyQueryReturnsRecentReaderPosts() {
        let context = ContextManager.forTesting().mainContext
        let older = ReaderPostBuilder(context).build()
        older.postTitle = "Older"
        older.postID = 1
        older.siteID = 9
        older.sortDate = Date(timeIntervalSince1970: 1000)
        let newer = ReaderPostBuilder(context).build()
        newer.postTitle = "Newer"
        newer.postID = 2
        newer.siteID = 9
        newer.sortDate = Date(timeIntervalSince1970: 2000)

        let results = ReaderPost.searchForAppIntent(matching: "", in: context)

        #expect(results == [newer, older])
    }

    @Test("reader posts cached under multiple topics are returned once")
    func deduplicatesReaderPosts() {
        let context = ContextManager.forTesting().mainContext
        let newest = ReaderPostBuilder(context).build()
        newest.postTitle = "Duplicate"
        newest.postID = 1
        newest.siteID = 9
        newest.sortDate = Date(timeIntervalSince1970: 3000)
        let duplicate = ReaderPostBuilder(context).build()
        duplicate.postTitle = "Duplicate"
        duplicate.postID = 1
        duplicate.siteID = 9
        duplicate.sortDate = Date(timeIntervalSince1970: 2000)
        let other = ReaderPostBuilder(context).build()
        other.postTitle = "Other"
        other.postID = 2
        other.siteID = 9
        other.sortDate = Date(timeIntervalSince1970: 1000)

        let results = ReaderPost.searchForAppIntent(matching: "", in: context)

        #expect(results == [newest, other])
    }

    @Test("excludes reader posts that cannot be identified")
    func excludesUnidentifiableReaderPosts() {
        let context = ContextManager.forTesting().mainContext
        let post = ReaderPostBuilder(context).build()
        post.postTitle = "Hello World"
        post.postID = 1

        #expect(ReaderPost.searchForAppIntent(matching: "world", in: context) == [])
    }
}
