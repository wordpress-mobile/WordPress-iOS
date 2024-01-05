import WordPressShared
import UIKit
/// This class groups all of the styles used by the comment detail screen.
///
extension WPStyleGuide {
    public struct CommentDetail {
        static let tintColor: UIColor = .primary

        static let textFont = WPStyleGuide.fontForTextStyle(.body)
        static let textColor = UIColor.text

        static let secondaryTextFont = WPStyleGuide.fontForTextStyle(.subheadline)
        static let secondaryTextColor = UIColor.textSubtle

        static let tertiaryTextFont = WPStyleGuide.fontForTextStyle(.caption2)

        public struct Header {
            static let font = CommentDetail.tertiaryTextFont
            static let textColor = CommentDetail.secondaryTextColor

            static let detailFont = CommentDetail.secondaryTextFont
            static let detailTextColor = CommentDetail.textColor
        }

        public struct Content {
            static let buttonTintColor: UIColor = .textSubtle
            static let likedTintColor: UIColor = .primary

            static let nameFont = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold)
            static let nameTextColor = CommentDetail.textColor

            static let badgeFont = WPStyleGuide.fontForTextStyle(.caption2, fontWeight: .semibold)
            static let badgeTextColor = UIColor.white
            static let badgeColor = UIColor.muriel(name: .blue, .shade50)

            static let dateFont = CommentDetail.tertiaryTextFont
            static let dateTextColor = CommentDetail.secondaryTextColor

            static let reactionButtonFont = WPStyleGuide.fontForTextStyle(.caption1)
            static let reactionButtonTextColor = UIColor.label

            // highlighted state
            static let highlightedBackgroundColor = UIColor(light: .muriel(name: .blue, .shade0), dark: .muriel(name: .blue, .shade100)).withAlphaComponent(0.5)
            static let highlightedBarBackgroundColor = UIColor.muriel(name: .blue, .shade40)
            static let highlightedReplyButtonTintColor = UIColor.primary

            static let placeholderImage = UIImage.gravatarPlaceholderImage

            private static let reactionIconConfiguration = UIImage.SymbolConfiguration(font: reactionButtonFont, scale: .large)
            static let unlikedIconImage = UIImage(systemName: "star", withConfiguration: reactionIconConfiguration)
            static let likedIconImage = UIImage(systemName: "star.fill", withConfiguration: reactionIconConfiguration)

            static let accessoryIconConfiguration = UIImage.SymbolConfiguration(font: CommentDetail.tertiaryTextFont, scale: .medium)
            static let shareIconImageName = "square.and.arrow.up"
            static let ellipsisIconImageName = "ellipsis.circle"
            static let infoIconImageName = "info.circle"


            static var replyIconImage: UIImage? {
                // this symbol is only available in iOS 14 and above. For iOS 13, we need to use the backported image in our assets.
                let name = "arrowshape.turn.up.backward"
                let image = UIImage(systemName: name) ?? UIImage(named: name)
                return image?.withConfiguration(reactionIconConfiguration).imageFlippedForRightToLeftLayoutDirection()
            }

            static let highlightedReplyIconImage = UIImage(systemName: "arrowshape.turn.up.left.fill", withConfiguration: reactionIconConfiguration)?
                .withTintColor(highlightedReplyButtonTintColor, renderingMode: .alwaysTemplate)
                .imageFlippedForRightToLeftLayoutDirection()
        }

        public struct ReplyIndicator {
            static let textAttributes: [NSAttributedString.Key: Any] = [
                .font: CommentDetail.secondaryTextFont,
                .foregroundColor: CommentDetail.secondaryTextColor
            ]

            private static let symbolConfiguration = UIImage.SymbolConfiguration(font: CommentDetail.secondaryTextFont, scale: .small)
            static let iconImage: UIImage? = .init(systemName: "arrowshape.turn.up.left.circle", withConfiguration: symbolConfiguration)?
                .withRenderingMode(.alwaysTemplate)
                .imageFlippedForRightToLeftLayoutDirection()
        }
    }
}
