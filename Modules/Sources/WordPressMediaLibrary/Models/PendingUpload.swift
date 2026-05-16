import Foundation
import WordPressAPI

/// View-model-facing surface of an in-flight upload. The actor stores a
/// richer internal value with the `Task` handle and owned temp-file URL.
struct PendingUpload: Identifiable, Sendable {
    let id: UUID
    let displayName: String // basename of the temp file
    let kind: MediaKind // for icon + Uploads-row rendering
    let progress: Progress // bound to ProgressView directly
}
