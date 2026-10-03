import Foundation
import Testing
import WordPressAPI

@testable import WordPress

/// Support attachments are handed to `wordpress-rs` as filesystem paths, which it opens directly.
/// `URL.path()` percent-encodes by default, so a filename needing encoding produced a path that
/// doesn't exist on disk and failed the whole ticket. Same shape as the media upload bug in #26005.
struct SupportAttachmentFilePathTests {

    /// A screenshot picked from the library keeps its original filename, and macOS names those
    /// with spaces.
    @Test func newTicketDecodesPercentEncodingInAttachmentPaths() {
        let params = CreateSupportTicketParams(
            subject: "Subject",
            message: "Message",
            application: "jetpack",
            attachmentURLs: [URL(fileURLWithPath: "/tmp/attachments/Screen Shot 1.png")]
        )

        #expect(params.attachments == ["/tmp/attachments/Screen Shot 1.png"])
    }

    /// Characters beyond the space get encoded too — including non-ASCII, which `path()` renders
    /// as UTF-8 escapes.
    @Test func newTicketDecodesPercentEncodingBeyondSpaces() {
        let params = CreateSupportTicketParams(
            subject: "Subject",
            message: "Message",
            application: "jetpack",
            attachmentURLs: [
                URL(fileURLWithPath: "/tmp/attachments/100% done.png"),
                URL(fileURLWithPath: "/tmp/attachments/café.png")
            ]
        )

        #expect(params.attachments == ["/tmp/attachments/100% done.png", "/tmp/attachments/café.png"])
    }

    /// A name needing no encoding has to survive untouched.
    @Test func newTicketLeavesAnOrdinaryPathAlone() {
        let params = CreateSupportTicketParams(
            subject: "Subject",
            message: "Message",
            application: "jetpack",
            attachmentURLs: [URL(fileURLWithPath: "/tmp/attachments/IMG_0001.png")]
        )

        #expect(params.attachments == ["/tmp/attachments/IMG_0001.png"])
    }

    /// The reply path builds a different params type, so it needs its own coverage.
    @Test func replyDecodesPercentEncodingInAttachmentPaths() {
        let params = AddMessageToSupportConversationParams(
            message: "Message",
            attachmentURLs: [URL(fileURLWithPath: "/tmp/attachments/Screen Shot 1.png")]
        )

        #expect(params.attachments == ["/tmp/attachments/Screen Shot 1.png"])
    }

    @Test func replyLeavesAnOrdinaryPathAlone() {
        let params = AddMessageToSupportConversationParams(
            message: "Message",
            attachmentURLs: [URL(fileURLWithPath: "/tmp/attachments/IMG_0001.png")]
        )

        #expect(params.attachments == ["/tmp/attachments/IMG_0001.png"])
    }

    /// No attachments is the common case and must not trip the mapping.
    @Test func emptyAttachmentsProduceNoPaths() {
        let params = AddMessageToSupportConversationParams(message: "Message", attachmentURLs: [])

        #expect(params.attachments.isEmpty)
    }
}
