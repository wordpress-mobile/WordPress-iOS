import Foundation
import WordPressData
import WordPressKit

extension RemotePostUpdateParameters {
    /// If the post was previously scheduled and these changes publish it
    /// without specifying a new date, sets the date to `now`; otherwise the
    /// server would leave the post scheduled instead of publishing it.
    mutating func setDateForImmediatePublishIfNeeded(previousStatus: BasePost.Status?, now: Date = .now) {
        guard status == Post.Status.publish.rawValue || status == Post.Status.publishPrivate.rawValue,
            previousStatus == .scheduled,
            date == nil
        else {
            return
        }
        date = now
    }
}
