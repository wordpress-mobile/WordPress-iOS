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
}
