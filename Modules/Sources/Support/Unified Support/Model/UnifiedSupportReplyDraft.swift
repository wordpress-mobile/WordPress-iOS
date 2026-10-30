import Foundation

/// The reply the user is writing to the support team.
///
/// The draft outlives the reply form, so a reply that fails to send isn't lost and can be sent again.
struct UnifiedSupportReplyDraft: Equatable {

    var message = ""

    /// Every file the user picked, including the ones that don't fit in one reply.
    var files: [UnifiedSupportPickedFile] = []

    var includeApplicationLogs = false

    /// Whether the user would lose something by closing the form.
    var isEmpty: Bool {
        message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && files.isEmpty && !includeApplicationLogs
    }

    var canSend: Bool {
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

/// A file the user picked to send with a reply, copied to a temporary location.
struct UnifiedSupportPickedFile: Identifiable, Equatable, Sendable {

    let id: UUID
    let url: URL

    /// The size of the file in bytes, or `0` when the system doesn't report one.
    let fileSize: UInt64

    var filename: String {
        url.lastPathComponent
    }

    init(id: UUID = UUID(), url: URL, fileSize: UInt64) {
        self.id = id
        self.url = url
        self.fileSize = fileSize
    }
}

/// Splits the files the user picked into the ones that fit in a single reply and the ones that don't.
///
/// Files are taken in the order they were picked, so removing an accepted file can make room for a skipped one.
struct UnifiedSupportAttachmentValidator {

    struct Result: Equatable {
        var accepted: [UnifiedSupportPickedFile] = []
        var skipped: [UnifiedSupportPickedFile] = []

        /// The size of the accepted files in bytes.
        var acceptedSize: UInt64 = 0

        /// The size of the files left out in bytes.
        var skippedSize: UInt64 = 0
    }

    let maximumUploadSize: UInt64

    func validate(_ files: [UnifiedSupportPickedFile]) -> Result {
        var result = Result()

        for file in files {
            // A file whose size the system doesn't report counts as empty, like on Android.
            if result.acceptedSize + file.fileSize <= maximumUploadSize {
                result.accepted.append(file)
                result.acceptedSize += file.fileSize
            } else {
                result.skipped.append(file)
                result.skippedSize += file.fileSize
            }
        }

        return result
    }
}
