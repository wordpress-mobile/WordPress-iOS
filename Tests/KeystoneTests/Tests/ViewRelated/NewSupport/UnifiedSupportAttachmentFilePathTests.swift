import Foundation
import Testing
import WordPressAPIInternal

@testable import WordPress

/// Reply attachments are handed to `wordpress-rs` as filesystem paths, which it opens directly.
/// `URL.path()` percent-encodes by default, so a filename needing encoding produced a path that
/// doesn't exist on disk and failed the whole reply. Same shape as the media upload bug in #26005.
struct UnifiedSupportAttachmentFilePathTests {

    /// A screenshot picked from the library keeps its original filename, and macOS names those
    /// with spaces.
    @Test func replyDecodesPercentEncodingInAttachmentPaths() {
        let params = ReplyToUnifiedConversationParams(
            message: "Message",
            encryptedLogIds: [],
            attachmentURLs: [URL(fileURLWithPath: "/tmp/attachments/Screen Shot 1.png")]
        )

        #expect(params.attachments == ["/tmp/attachments/Screen Shot 1.png"])
    }

    /// Characters beyond the space get encoded too — including non-ASCII, which `path()` renders
    /// as UTF-8 escapes.
    @Test func replyDecodesPercentEncodingBeyondSpaces() {
        let params = ReplyToUnifiedConversationParams(
            message: "Message",
            encryptedLogIds: [],
            attachmentURLs: [
                URL(fileURLWithPath: "/tmp/attachments/100% done.png"),
                URL(fileURLWithPath: "/tmp/attachments/café.png")
            ]
        )

        #expect(params.attachments == ["/tmp/attachments/100% done.png", "/tmp/attachments/café.png"])
    }

    /// A name needing no encoding has to survive untouched.
    @Test func replyLeavesAnOrdinaryPathAlone() {
        let params = ReplyToUnifiedConversationParams(
            message: "Message",
            encryptedLogIds: [],
            attachmentURLs: [URL(fileURLWithPath: "/tmp/attachments/IMG_0001.png")]
        )

        #expect(params.attachments == ["/tmp/attachments/IMG_0001.png"])
    }

    /// No attachments is the common case and must not trip the mapping.
    @Test func emptyAttachmentsProduceNoPaths() {
        let params = ReplyToUnifiedConversationParams(
            message: "Message",
            encryptedLogIds: [],
            attachmentURLs: []
        )

        #expect(params.attachments.isEmpty)
    }

    /// The logs ride along with the attachments, so the initializer has to pass them through.
    @Test func replyKeepsEncryptedLogIds() {
        let params = ReplyToUnifiedConversationParams(
            message: "Message",
            encryptedLogIds: ["log-1", "log-2"],
            attachmentURLs: []
        )

        #expect(params.encryptedLogIds == ["log-1", "log-2"])
    }
}
