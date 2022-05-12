import Foundation
import CoreData
import WordPressKit

public class BloggingPrompt: NSManagedObject {
    /// Convenience method to map properties from `RemoteBloggingPrompt`.
    ///
    /// - Parameters:
    ///   - remotePrompt: The remote prompt model to convert
    ///   - siteID: The ID of the site that the prompt is intended for
    func configure(with remotePrompt: RemoteBloggingPrompt, for siteID: Int32) {
        self.promptID = Int32(remotePrompt.promptID)
        self.siteID = siteID
        self.text = remotePrompt.text
        self.title = remotePrompt.title
        self.content = remotePrompt.content
        self.attribution = remotePrompt.attribution
        self.date = remotePrompt.date
        self.answered = remotePrompt.answered
        self.answerCount = Int32(remotePrompt.answeredUsersCount)
        self.displayAvatarURLs = remotePrompt.answeredUserAvatarURLs
    }
}
