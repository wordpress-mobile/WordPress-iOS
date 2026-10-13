import Foundation
import WordPressData
import WordPressShared

enum AbstractPostHelper {
    static func getLocalizedStatusWithDate(for post: AbstractPost) -> String? {
        let timeZone = post.blog.timeZone
        let context = Formatter.Context.beginningOfSentence

        switch post.status {
        case .scheduled:
            if let dateCreated = post.dateCreated {
                return dateCreated.mediumStringWithTime(timeZone: timeZone, formattingContext: context)
            }
        case .publish, .publishPrivate:
            if let dateCreated = post.dateCreated {
                return dateCreated.toMediumString(inTimeZone: timeZone, formattingContext: context)
            }
        case .trash:
            if let dateModified = post.dateModified {
                return dateModified.toMediumString(inTimeZone: timeZone, formattingContext: context)
            }
        default:
            break
        }
        if let dateModified = post.dateModified {
            return dateModified.toMediumString(inTimeZone: timeZone, formattingContext: context)
        }
        if let dateCreated = post.dateCreated {
            return dateCreated.toMediumString(inTimeZone: timeZone, formattingContext: context)
        }
        return nil
    }

    static func makeBadgesString(with badges: [(String, UIColor?)]) -> NSAttributedString {
        let string = NSMutableAttributedString()
        for (badge, color) in badges {
            if string.length > 0 {
                string.append(NSAttributedString(string: " · ", attributes: [
                    .foregroundColor: UIColor.secondaryLabel,
                    .font: UIFont.preferredFont(forTextStyle: .footnote).withWeight(.bold)
                ]))
            }
            string.append(NSAttributedString(string: badge, attributes: [
                .foregroundColor: color ?? UIColor.secondaryLabel,
                .font: UIFont.preferredFont(forTextStyle: .footnote)
            ]))
        }
        return string
    }
}
