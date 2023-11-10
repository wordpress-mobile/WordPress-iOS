import Foundation
import CoreData
import WordPressKit

public class BloggingPrompt: NSManagedObject {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BloggingPrompt> {
        return NSFetchRequest<BloggingPrompt>(entityName: Self.classNameWithoutNamespaces())
    }

    @nonobjc public class func newObject(in context: NSManagedObjectContext) -> BloggingPrompt? {
        return NSEntityDescription.insertNewObject(forEntityName: Self.classNameWithoutNamespaces(), into: context) as? BloggingPrompt
    }

    public override func awakeFromInsert() {
        self.date = .init(timeIntervalSince1970: 0)
        self.displayAvatarURLs = []
    }

    var promptAttribution: BloggingPromptsAttribution? {
        BloggingPromptsAttribution(rawValue: attribution.lowercased())
    }

    /// Convenience method to map properties from `BloggingPromptRemoteObject`.
    ///
    /// - Parameters:
    ///   - remotePrompt: The remote prompt model to convert
    ///   - siteID: The ID of the site that the prompt is intended for
    func configure(with remotePrompt: BloggingPromptRemoteObject, for siteID: Int32) {
        self.promptID = Int32(remotePrompt.promptID)
        self.siteID = siteID
        self.text = remotePrompt.text
        self.attribution = remotePrompt.attribution
        self.date = remotePrompt.date
        self.answered = remotePrompt.answered
        self.answerCount = Int32(remotePrompt.answeredUsersCount)
        self.displayAvatarURLs = remotePrompt.answeredUserAvatarURLs

        if let brandContext = BrandContext(with: remotePrompt) {
            brandContext.configure(self)
        }
    }

    func textForDisplay() -> String {
        return text.stringByDecodingXMLCharacters().trim()
    }

    /// Convenience method that checks if the given date is within the same day of the prompt's date without considering the timezone information.
    ///
    /// Example: `2022-05-19 23:00:00 UTC-5` and `2022-05-20 00:00:00 UTC` are both dates within the same day (when the UTC date is converted to UTC-5),
    /// but this method will return `false`.
    ///
    /// - Parameters:
    ///   - localDate: The date to compare against in local timezone.
    /// - Returns: True if the year, month, and day components of the `localDate` matches the prompt's localized date.
    func inSameDay(as dateToCompare: Date) -> Bool {
        return DateFormatters.utc.string(from: date) == DateFormatters.local.string(from: dateToCompare)
    }
}

// MARK: - Notification Payload

extension BloggingPrompt {

    struct NotificationKeys {
        static let promptID = "prompt_id"
        static let siteID = "site_id"
    }

}

// MARK: - Private Helpers

private extension BloggingPrompt {

    enum Constants {
        static let bloganuaryTag = "bloganuary"
    }

    enum BrandContext {
        case bloganuary(String)

        init?(with remotePrompt: BloggingPromptRemoteObject) {
            // Bloganuary context
            if let bloganuaryId = remotePrompt.bloganuaryId,
               bloganuaryId.contains(Constants.bloganuaryTag) {
                self = .bloganuary(bloganuaryId)
                return
            }

            return nil
        }

        /// Configures the given prompt with additional data based on the brand context.
        ///
        /// - Parameter prompt: The `BloggingPrompt` instance to configure.
        func configure(_ prompt: BloggingPrompt) {
            switch self {
            case .bloganuary(let id):
                prompt.additionalPostTags = [Constants.bloganuaryTag, id]
                prompt.attribution = BloggingPromptsAttribution.bloganuary.rawValue
            }
        }
    }

    struct DateFormatters {
        static let local: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = .init(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter
        }()

        static let utc: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = .init(identifier: "en_US_POSIX")
            formatter.timeZone = .init(secondsFromGMT: 0)
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter
        }()
    }

}
