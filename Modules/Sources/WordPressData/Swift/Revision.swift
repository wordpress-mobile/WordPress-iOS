import Foundation
import CoreData

public class Revision: NSManagedObject {
    @NSManaged public var siteId: NSNumber
    @NSManaged public var revisionId: NSNumber
    @NSManaged public var postId: NSNumber

    @NSManaged public var postAuthorId: NSNumber?

    @NSManaged public var postTitle: String?
    @NSManaged public var postContent: String?
    @NSManaged public var postExcerpt: String?

    @NSManaged public var postDateGmt: String?
    @NSManaged public var postModifiedGmt: String?

    @NSManaged public var diff: RevisionDiff?

    private lazy var revisionFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    public var revisionDate: Date {
        return revisionFormatter.date(from: postDateGmt ?? "") ?? Date()
    }

    @objc public var revisionDateForSection: String {
        return revisionDate.longUTCStringWithoutTime()
    }
}
