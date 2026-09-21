import Foundation

extension Error {

    /// The message to show the user for this error.
    ///
    /// Errors that describe themselves are shown as they are. For the rest, a generic message is shown instead of
    /// `localizedDescription`, which for a Swift error without a message reads "The operation couldn't be completed.
    /// (Module.Error error 1.)".
    var unifiedSupportMessage: String {
        if let description = (self as? LocalizedError)?.errorDescription {
            return description
        }

        let error = self as NSError
        if error.userInfo[NSLocalizedDescriptionKey] != nil {
            return error.localizedDescription
        }

        return UnifiedSupportLocalization.genericErrorMessage
    }

    /// Whether the request was cancelled, which happens when the user leaves the screen while it's loading.
    var isUnifiedSupportCancellation: Bool {
        self is CancellationError || (self as? URLError)?.code == .cancelled
    }
}
