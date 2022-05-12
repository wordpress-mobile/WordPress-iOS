import Foundation
import CoreData
import WordPressKit

public class BloggingPrompt: NSManagedObject {

    enum AttributionSource: String {
        case none
        case dayOne = "dayone"

        init(with stringValue: String) {
            self = AttributionSource(rawValue: stringValue) ?? .none
        }
    }

    var attributionSource: AttributionSource {
        .init(with: attribution)
    }

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
