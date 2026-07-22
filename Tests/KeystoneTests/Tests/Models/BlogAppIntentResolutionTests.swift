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

    @Test("no identifier falls back to the last used or first blog")
    func missingIdentifierFallsBack() {
        let context = ContextManager.forTesting().mainContext
        let blog = BlogBuilder(context).with(dotComID: 111).build()

        #expect(Blog.forAppIntent(siteIdentifier: nil, in: context) == blog)
    }
}
