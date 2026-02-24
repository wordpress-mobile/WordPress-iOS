import Testing
import UIKit
@testable import WordPressData

@MainActor
struct ReaderPostTests {
    private let contextManager = ContextManager.forTesting()
    private var mainContext: NSManagedObjectContext { contextManager.mainContext }

    private func makeReaderPost() -> ReaderPost {
        NSEntityDescription.insertNewObject(forEntityName: ReaderPost.entityName(), into: mainContext) as! ReaderPost
    }

    // MARK: - Site Icon URL

    @Test func siteIconURLReturnsNilWhenNotSet() {
        let post = makeReaderPost()
        #expect(post.getSiteIconURL(size: 50) == nil)
    }

    @Test func siteIconURLReturnsURLForRegularIcon() {
        let post = makeReaderPost()
        post.siteIconURL = "http://example.com/icon.png"
        #expect(post.getSiteIconURL(size: 50) == URL(string: "http://example.com/icon.png"))
    }

    @Test func siteIconURLScalesGravatarURL() throws {
        let post = makeReaderPost()
        post.siteIconURL = "https://gravatar.com/blavatar/icon.png"

        let scaledURL = try #require(post.getSiteIconURL(size: 50))
        let components = try #require(URLComponents(url: scaledURL, resolvingAgainstBaseURL: false))
        let queryItems = components.queryItems ?? []
        #expect(queryItems.count == 2)
        #expect(queryItems.first(where: { $0.name == "s" })?.value == Int(50 * UITraitCollection.current.displayScale).description)
        #expect(queryItems.first(where: { $0.name == "d" })?.value == "404")
    }

    // MARK: - Blog Name

    @Test func blogNameForDisplayCollapsesWhitespace() {
        let post = makeReaderPost()
        post.blogName = "t          r          e          f          o          l          o          g          y"
        #expect(post.blogNameForDisplay() == "t r e f o l o g y")
    }
}
