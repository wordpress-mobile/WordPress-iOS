import Foundation
import Testing

@testable import WordPress
@testable import WordPressData

@MainActor
@Suite("Blog app intent resolution")
struct BlogAppIntentResolutionTests {
    @Test("a site identifier resolves the matching blog")
    func explicitIdentifierResolvesMatchingBlog() {
        let context = ContextManager.forTesting().mainContext
        BlogBuilder(context).with(dotComID: 111).build()
        let target = BlogBuilder(context).with(dotComID: 222).build()

        #expect(Blog.forAppIntent(siteIdentifier: "222", in: context) == target)
    }

    @Test("an identifier with no matching blog resolves nothing instead of falling back")
    func unknownIdentifierResolvesNil() {
        let context = ContextManager.forTesting().mainContext
        BlogBuilder(context).with(dotComID: 111).build()

        #expect(Blog.forAppIntent(siteIdentifier: "999", in: context) == nil)
    }

    @Test("a non-numeric identifier resolves nothing")
    func nonNumericIdentifierResolvesNil() {
        let context = ContextManager.forTesting().mainContext
        BlogBuilder(context).with(dotComID: 111).build()

        #expect(Blog.forAppIntent(siteIdentifier: "not-a-number", in: context) == nil)
    }

    @Test("with no explicit or last-used site, resolves the first blog by name")
    func missingIdentifierResolvesFirstBlog() {
        let context = ContextManager.forTesting().mainContext
        // Insert out of alphabetical order and give each blog a unique URL so a
        // stale global "recent sites" entry can never match one of them. With no
        // last-used site and no default account resolvable in this isolated
        // context, `lastUsedOrFirst` reaches its `firstBlog` branch, which sorts
        // by `settings.name` ascending — so "Alpha", not the earlier-inserted
        // "Zulu", must win.
        BlogBuilder(context)
            .with(dotComID: 222)
            .with(url: "https://zulu-appintent-test.example.com")
            .with(siteName: "Zulu Site")
            .build()
        let alpha = BlogBuilder(context)
            .with(dotComID: 111)
            .with(url: "https://alpha-appintent-test.example.com")
            .with(siteName: "Alpha Site")
            .build()

        // The specific blog is the point: with two candidates, "returns non-nil"
        // could not tell a correct fallback from a broken one.
        #expect(Blog.forAppIntent(siteIdentifier: nil, in: context) == alpha)
    }

    @Test("with no sites at all, no identifier resolves nothing")
    func missingIdentifierWithNoBlogsResolvesNil() {
        let context = ContextManager.forTesting().mainContext

        #expect(Blog.forAppIntent(siteIdentifier: nil, in: context) == nil)
    }
}
