import Foundation
import Testing

@testable import WordPress
@testable import WordPressData

@MainActor
@Suite("Reader user profile view model")
struct ReaderUserProfileViewModelTests {
    private let contextManager = ContextManager.forTesting()

    @Test("Decodes the entities in a comment author's name, as the comment does")
    func commentAuthor() {
        let comment = Comment(context: contextManager.mainContext)
        comment.author = "Tom &amp; Jerry"

        #expect(ReaderUserProfileViewModel(comment: comment).name == "Tom & Jerry")
    }

    @Test(
        "Offers a site only when its address opens a website",
        arguments: [
            ("https://example.com", true),
            ("http://example.com/blog", true),
            ("HTTPS://EXAMPLE.COM", true),
            ("example.com", false),
            ("http://", false),
            ("https:example.com", false),
            ("tel:+19005550100", false),
            ("sms:+19005550100", false),
            ("javascript:alert(1)", false),
            ("", false)
        ]
    )
    func site(address: String, isOffered: Bool) {
        let expected = isOffered ? URL(string: address) : nil
        let comment = Comment(context: contextManager.mainContext)
        comment.author_url = address
        let post = ReaderPost(context: contextManager.mainContext)
        post.blogURL = address
        let profile = ReaderUserProfile(
            username: "example-user",
            displayName: "Example User",
            avatarURL: nil,
            siteURL: URL(string: address),
            bio: nil
        )

        #expect(ReaderUserProfileViewModel(comment: comment).siteURL == expected)
        #expect(ReaderUserProfileViewModel(post: post).siteURL == expected)
        #expect(ReaderUserProfileViewModel(profile: profile).siteURL == expected)
    }

    @Test("Only a profile fetched for a mention has a bio")
    func bio() {
        let profile = ReaderUserProfile(
            username: "example-user",
            displayName: "Example User",
            avatarURL: nil,
            siteURL: nil,
            bio: "Writes about bread."
        )
        let comment = Comment(context: contextManager.mainContext)
        let post = ReaderPost(context: contextManager.mainContext)

        #expect(ReaderUserProfileViewModel(profile: profile).bio == "Writes about bread.")
        #expect(ReaderUserProfileViewModel(comment: comment).bio == nil)
        #expect(ReaderUserProfileViewModel(post: post).bio == nil)
    }
}
