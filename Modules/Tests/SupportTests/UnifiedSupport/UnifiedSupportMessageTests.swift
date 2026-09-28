import Foundation
import Testing
@testable import Support

struct UnifiedSupportMessageTests {

    @Test(arguments: [
        ("user", UnifiedSupportMessage.AuthorRole.user),
        ("bot", .bot),
        ("support", .support),
        ("SYSTEM", .system),
        ("agent", .unknown)
    ])
    func mapsAuthorRole(_ serverValue: String, to expected: UnifiedSupportMessage.AuthorRole) {
        #expect(UnifiedSupportMessage.AuthorRole(serverValue: serverValue) == expected)
    }

    @Test func appliesMarkdownFormatting() {
        let message = UnifiedSupportMessage.make(content: "Some **bold** text")

        #expect(String(message.attributedContent.characters) == "Some bold text")
    }
}

struct UnifiedSupportAttachmentTests {

    @Test(arguments: [
        ("image/png", UnifiedSupportAttachment.Kind.image),
        ("IMAGE/JPEG", .image),
        ("video/mp4", .video),
        ("text/html", .link),
        ("text/html; charset=utf-8", .link),
        ("application/pdf", .other),
        ("text/plain", .other)
    ])
    func determinesKindFromContentType(_ contentType: String, expected: UnifiedSupportAttachment.Kind) {
        let attachment = UnifiedSupportAttachment(
            remoteId: 1,
            filename: "file",
            contentType: contentType,
            fileSize: 0,
            url: URL(string: "https://example.com/file")!
        )

        #expect(attachment.kind == expected)
    }

    /// The server sends every page the AI Assistant used as a source with an ID of 0.
    @Test func sourcesOfTheSameAnswerAreToldApart() {
        let sources = [
            makeSource(filename: "Enable WP Cache debugging", url: "https://jetpack.com/support/wp-super-cache/"),
            makeSource(filename: "Post by Email", url: "https://jetpack.com/support/post-by-email/"),
            makeSource(filename: "Known issues", url: "https://jetpack.com/support/known-issues/")
        ]

        #expect(Set(sources.map(\.id)).count == sources.count)
    }

    private func makeSource(filename: String, url: String) -> UnifiedSupportAttachment {
        UnifiedSupportAttachment(
            remoteId: 0,
            filename: filename,
            contentType: "text/html",
            fileSize: 0,
            url: URL(string: url)!
        )
    }
}
