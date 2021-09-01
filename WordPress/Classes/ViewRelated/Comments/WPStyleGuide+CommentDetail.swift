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

        public struct Header {
            static let font = WPStyleGuide.fontForTextStyle(.footnote)
            static let textColor = CommentDetail.secondaryTextColor

            static let detailFont = CommentDetail.secondaryTextFont
            static let detailTextColor = CommentDetail.textColor
        }

        public struct ReplyIndicator {
            static let textAttributes: [NSAttributedString.Key: Any] = [
                .font: CommentDetail.secondaryTextFont,
                .foregroundColor: CommentDetail.secondaryTextColor
            ]

            private static let symbolName = "arrowshape.turn.up.left.circle"
            private static let symbolConfiguration = UIImage.SymbolConfiguration(font: CommentDetail.secondaryTextFont, scale: .small)
            static let iconImage: UIImage? = .init(systemName: symbolName, withConfiguration: symbolConfiguration)?
                .withRenderingMode(.alwaysTemplate)
                .imageFlippedForRightToLeftLayoutDirection()
        }
    }
}
