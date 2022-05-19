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

    func textForDisplay() -> String {
        return text.stringByDecodingXMLCharacters().trim()
    }

    var localDate: Date? {
        let dateString = DateFormatters.utc.string(from: date)
        return DateFormatters.local.date(from: dateString)
    }

    /// Convenience method that matches local date to the prompt's UTC date.
    ///
    /// Before checking, the prompt date is "localized" to avoid -1/+1 day issue due to local timezone. This method only checks if the prompt date
    /// matches the year, month, and day of the given `localDate`. The time information is ignored.
    ///
    /// - Parameters:
    ///   - localDate: The date to compare against in local timezone.
    /// - Returns: True if the year, month, and day components of the `localDate` matches the prompt's localized date.
    func inSameDay(as dateToCompare: Date) -> Bool {
        guard let localDate = localDate else {
            return false
        }

        return Calendar.current.isDate(dateToCompare, inSameDayAs: localDate)
//
//        guard let utcTimeZone = TimeZone(secondsFromGMT: 0) else {
//            return false
//        }
//
//        let calendar = Calendar.current
//        let localizedComponents = calendar.dateComponents(in: utcTimeZone, from: date)
//        let components: Set<Calendar.Component> = [.year, .month, .day]
//        let diffs = calendar.dateComponents(components, from: localDate.dateAndTimeComponents(), to: localizedComponents)
//
//        return components.reduce(true) { partialResult, component in
//            let value = diffs.value(for: component) ?? -1
//            return partialResult && (value == 0)
//        }
    }


}

// MARK: - Private Helpers

private extension BloggingPrompt {

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
