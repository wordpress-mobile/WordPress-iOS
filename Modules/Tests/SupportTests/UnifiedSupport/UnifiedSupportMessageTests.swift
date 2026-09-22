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
            id: 1,
            filename: "file",
            contentType: contentType,
            fileSize: 0,
            url: URL(string: "https://example.com/file")!
        )

        #expect(attachment.kind == expected)
    }
}
