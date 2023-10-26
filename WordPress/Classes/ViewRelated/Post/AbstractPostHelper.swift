import Foundation

enum AbstractPostHelper {
    static func getLocalizedStatusWithDate(for post: AbstractPost) -> String? {
        let timeZone = post.blog.timeZone

        switch post.status {
        case .scheduled:
            if let dateCreated = post.dateCreated {
                return String(format: Strings.scheduled, dateCreated.mediumStringWithTime(timeZone: timeZone))
            }
        case .publish, .publishPrivate:
            if let dateCreated = post.dateCreated {
                return String(format: Strings.published, dateCreated.toMediumString(inTimeZone: timeZone))
            }
        case .trash:
            if let dateCreated = post.dateCreated {
                return String(format: Strings.trashed, dateCreated.toMediumString(inTimeZone: timeZone))
            }
        default:
            break
        }
        if let dateModified = post.dateModified {
            return String(format: Strings.edited, dateModified.toMediumString(inTimeZone: timeZone))
        }
        if let dateCreated = post.dateCreated {
            return String(format: Strings.created, dateCreated.toMediumString(inTimeZone: timeZone))
        }
        return nil
    }
}

private enum Strings {
    static let published = NSLocalizedString("post.publishedTimeAgo", value: "Published %@", comment: "Post status and date for list cells")
    static let scheduled = NSLocalizedString("post.scheduledForDate", value: "Scheduled %@", comment: "Post status and date for list cells")
    static let created = NSLocalizedString("post.createdTimeAgo", value: "Created %@", comment: "Post status and date for list cells")
    static let edited = NSLocalizedString("post.editedTimeAgo", value: "Edited %@", comment: "Post status and date for list cells")
    static let trashed = NSLocalizedString("post.trashedTimeAgo", value: "Trashed %@", comment: "Post status and date for list cells")
}
