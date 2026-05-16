import Foundation

struct FailedUpload: Identifiable, Sendable {
    let id: UUID
    let displayName: String
    let kind: MediaKind
    /// Localized error message. The uploader stores
    /// `(error as NSError).localizedDescription` for HTTP failures and a
    /// localized materializer-error message for pre-upload failures.
    let errorMessage: String
    /// True when the actor can rerun the upload from the stored params +
    /// temp file. False for materialization failures, where the original
    /// `MediaCreateParams` / temp file were never produced — the
    /// Uploads-screen row should offer Dismiss only.
    let isRetryable: Bool
}
