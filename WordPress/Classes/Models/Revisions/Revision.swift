import Foundation
import CoreData


class Revision: NSManagedObject {
    @NSManaged var siteId: NSNumber
    @NSManaged var revisionId: NSNumber
    @NSManaged var postId: NSNumber

    @NSManaged var postAuthorId: NSNumber?

    @NSManaged var postTitle: String?
    @NSManaged var postContent: String?
    @NSManaged var postExcerpt: String?

    @NSManaged var postDateGmt: String?
    @NSManaged var postModifiedGmt: String?

    @NSManaged var diff: RevisionDiff?

    @objc var revisionDate: String {
        let date = formatter.date(from: postDateGmt ?? "") ?? Date()
        return date.toStringForPageSections()
    }

    private lazy var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}
