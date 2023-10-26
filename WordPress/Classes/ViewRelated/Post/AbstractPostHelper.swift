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
            if let dateModified = post.dateModified {
                return String(format: Strings.trashed, dateModified.toMediumString(inTimeZone: timeZone))
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

    static func makeBadgesString(with badges: [(String, UIColor?)]) -> NSAttributedString {
        var string = NSMutableAttributedString()
        for (badge, color) in badges {
            if string.length > 0 {
                string.append(NSAttributedString(string: " · ", attributes: [
                    .foregroundColor: UIColor.secondaryLabel
                ]))
            }
            string.append(NSAttributedString(string: badge, attributes: [
                .foregroundColor: color ?? UIColor.secondaryLabel
            ]))
        }
        string.addAttribute(.font, value: WPStyleGuide.fontForTextStyle(.footnote), range: NSRange(location: 0, length: string.length))
        return string
    }
}

private enum Strings {
    static let published = NSLocalizedString("post.publishedTimeAgo", value: "Published %@", comment: "Post status and date for list cells")
    static let scheduled = NSLocalizedString("post.scheduledForDate", value: "Scheduled %@", comment: "Post status and date for list cells")
    static let created = NSLocalizedString("post.createdTimeAgo", value: "Created %@", comment: "Post status and date for list cells")
    static let edited = NSLocalizedString("post.editedTimeAgo", value: "Edited %@", comment: "Post status and date for list cells")
    static let trashed = NSLocalizedString("post.trashedTimeAgo", value: "Trashed %@", comment: "Post status and date for list cells")
}
