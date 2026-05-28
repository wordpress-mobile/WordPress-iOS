import WordPressData
import WordPressKit

extension AbstractPost {
    /// Returns the changes made in the current revision compared to the
    /// previous revision or the original post if there is only one revision.
    var changes: RemotePostUpdateParameters {
        guard let original else {
            return RemotePostUpdateParameters() // Empty
        }
        return RemotePostUpdateParameters.changes(from: original, to: self)
    }
}
