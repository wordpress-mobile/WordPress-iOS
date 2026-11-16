import Foundation

struct FailedUpload: Identifiable, Sendable {
    let id: UUID
    let displayName: String
    let kind: MediaKind
    /// Localized error message. The uploader stores
    /// `(error as NSError).localizedDescription` for HTTP failures and a
    /// localized materializer-error message for pre-upload failures.
    let errorMessage: String
    /// True when the actor can retry a staged upload or repeat preparation
    /// after a recognized temporary failure. Other failures are remove-only.
    let isRetryable: Bool
}
