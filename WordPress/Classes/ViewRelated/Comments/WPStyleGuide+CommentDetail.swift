/// This class groups all of the styles used by the comment detail screen.
///
extension WPStyleGuide {
    public struct CommentDetail {
        static let tintColor: UIColor = .primary
        static let externalIconImage: UIImage = .gridicon(.external).imageFlippedForRightToLeftLayoutDirection()

        static let textFont = WPStyleGuide.fontForTextStyle(.body)
        static let textColor = UIColor.text

        static let secondaryTextFont = WPStyleGuide.fontForTextStyle(.subheadline)
        static let secondaryTextColor = UIColor.textSubtle

        static let tertiaryTextFont = WPStyleGuide.fontForTextStyle(.footnote)

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

            static let dateFont = CommentDetail.tertiaryTextFont
            static let dateTextColor = CommentDetail.secondaryTextColor

            static let reactionButtonFont = CommentDetail.secondaryTextFont
            static let reactionButtonTextColor = CommentDetail.secondaryTextColor

            static let placeholderImage = UIImage.gravatarPlaceholderImage

            private static let reactionIconConfiguration = UIImage.SymbolConfiguration(font: reactionButtonFont, scale: .medium)
            static let replyIconImage = UIImage(systemName: "arrowshape.turn.up.backward", withConfiguration: reactionIconConfiguration)
            static let unlikedIconImage = UIImage(systemName: "star", withConfiguration: reactionIconConfiguration)
            static let likedIconImage = UIImage(systemName: "star.fill", withConfiguration: reactionIconConfiguration)

            static let accessoryIconConfiguration = UIImage.SymbolConfiguration(font: CommentDetail.tertiaryTextFont, scale: .large)
            static let shareIconImageName = "square.and.arrow.up"
            static let threeDotsIconImageName = "ellipsis.circle"
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
