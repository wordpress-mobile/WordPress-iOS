import Foundation
import CoreData

extension BloggingPrompt {
    /// The unique ID for the prompt, received from the server.
    @NSManaged public var promptID: Int32

    /// The site ID for the prompt.
    @NSManaged public var siteID: Int32

    /// The prompt content to be displayed at entry points.
    @NSManaged public var text: String

    /// The attribution source for the prompt.
    @NSManaged public var attribution: String

    /// The prompt date. Time information should be ignored.
    @NSManaged public var date: Date

    /// Whether the current user has answered the prompt in `siteID`.
    @NSManaged public var answered: Bool

    /// The number of users that has answered the prompt.
    @NSManaged public var answerCount: Int32

    /// Contains avatar URLs of some users that have answered the prompt.
    @NSManaged public var displayAvatarURLs: [URL]

    /// Contains additional tags that should be appended to the post for this prompt's answer.
    @NSManaged public var additionalPostTags: [String]?
}
