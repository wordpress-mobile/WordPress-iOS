import Foundation

enum AbstractPostHelper {
    static func getLocalizedStatusWithDate(for post: AbstractPost) -> String? {
        _getLocalizedStatusWithDate(for: post)?.capitalized(with: .current)
    }

    private static func _getLocalizedStatusWithDate(for post: AbstractPost) -> String? {
        let timeZone = post.blog.timeZone

        switch post.status {
        case .scheduled:
            if let dateCreated = post.dateCreated {
                return dateCreated.mediumStringWithTime(timeZone: timeZone)
            }
        case .publish, .publishPrivate:
            if let dateCreated = post.dateCreated {
                return dateCreated.toMediumString(inTimeZone: timeZone)
            }
        case .trash:
            if let dateModified = post.dateModified {
                return dateModified.toMediumString(inTimeZone: timeZone)
            }
        default:
            break
        }
        if let dateModified = post.dateModified {
            return dateModified.toMediumString(inTimeZone: timeZone)
        }
        if let dateCreated = post.dateCreated {
            return dateCreated.toMediumString(inTimeZone: timeZone)
        }
        return nil
    }

    static func makeBadgesString(with badges: [(String, UIColor?)]) -> NSAttributedString {
        let string = NSMutableAttributedString()
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
