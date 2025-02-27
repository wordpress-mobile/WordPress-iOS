import WordPressShared
import UIKit
/// This class groups all of the styles used by the comment detail screen.
///
extension WPStyleGuide {
    public struct CommentDetail {
        static let tintColor: UIColor = UIAppColor.primary

        static let textFont = WPStyleGuide.fontForTextStyle(.body)
        static let textColor = UIColor.label

        static let secondaryTextFont = WPStyleGuide.fontForTextStyle(.subheadline)
        static let secondaryTextColor = UIColor.secondaryLabel

        static let tertiaryTextFont = WPStyleGuide.fontForTextStyle(.caption2)

        public struct Header {
            static let font = CommentDetail.tertiaryTextFont
            static let textColor = CommentDetail.secondaryTextColor

            static let detailFont = CommentDetail.secondaryTextFont
            static let detailTextColor = CommentDetail.textColor
        }

        public struct Content {
            static let nameFont = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold)
            static let nameTextColor = CommentDetail.textColor

            static let badgeFont = WPStyleGuide.fontForTextStyle(.caption2, fontWeight: .semibold)
            static let badgeTextColor = UIColor.white
            static let badgeColor = UIAppColor.blue(.shade50)

            static let dateFont = CommentDetail.tertiaryTextFont
            static let dateTextColor = CommentDetail.secondaryTextColor

            // highlighted state
            static let highlightedBackgroundColor = UIColor(
                light: UIAppColor.blue(.shade0),
                dark: UIAppColor.blue(.shade100)
            ).withAlphaComponent(0.5)
            static let highlightedBarBackgroundColor = UIAppColor.blue(.shade40)

            static let placeholderImage = UIImage.gravatarPlaceholderImage
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
