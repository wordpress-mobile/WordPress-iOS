import WordPressShared
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

            static let badgeFont = WPStyleGuide.fontForTextStyle(.caption2, fontWeight: .semibold)
            static let badgeTextColor = UIColor.white
            static let badgeColor = UIColor.muriel(name: .blue, .shade50)

            static let dateFont = CommentDetail.tertiaryTextFont
            static let dateTextColor = CommentDetail.secondaryTextColor

            static let reactionButtonFont = CommentDetail.secondaryTextFont
            static let reactionButtonTextColor = CommentDetail.secondaryTextColor

            // highlighted state
            static let highlightedBackgroundColor = UIColor(light: .muriel(name: .blue, .shade0), dark: .muriel(name: .blue, .shade100)).withAlphaComponent(0.5)
            static let highlightedBarBackgroundColor = UIColor.muriel(name: .blue, .shade40)
            static let highlightedReplyButtonTintColor = UIColor.primary

            static let placeholderImage = UIImage.gravatarPlaceholderImage

            private static let reactionIconConfiguration = UIImage.SymbolConfiguration(font: reactionButtonFont, scale: .medium)
            static let unlikedIconImage = UIImage(systemName: "star", withConfiguration: reactionIconConfiguration)
            static let likedIconImage = UIImage(systemName: "star.fill", withConfiguration: reactionIconConfiguration)

            static let accessoryIconConfiguration = UIImage.SymbolConfiguration(font: CommentDetail.tertiaryTextFont, scale: .large)
            static let shareIconImageName = "square.and.arrow.up"
            static let ellipsisIconImageName = "ellipsis.circle"

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

        public struct ModerationBar {
            static let barBackgroundColor: UIColor = .systemGray6
            static let cornerRadius: CGFloat = 15.0

            static let dividerColor: UIColor = .systemGray
            static let dividerHiddenColor: UIColor = .clear

            static let buttonShadowOffset = CGSize(width: 0, height: 2.0)
            static let buttonShadowOpacity: Float = 0.25
            static let buttonShadowRadius: CGFloat = 2.0

            static let buttonDefaultTitleColor = UIColor(light: .textSubtle, dark: .systemGray)
            static let buttonSelectedTitleColor = UIColor(light: .black, dark: .white)
            static let buttonDefaultBackgroundColor: UIColor = .clear
            static let buttonDefaultShadowColor = UIColor.clear.cgColor
            static let buttonSelectedBackgroundColor: UIColor = .tertiaryBackground
            static let buttonSelectedShadowColor = UIColor.black.cgColor

            static let pendingImageName = "tray"
            static let approvedImageName = "checkmark.circle"
            static let spamImageName = "exclamationmark.octagon"
            static let trashImageName = "trash"

            static let imageDefaultTintColor = buttonDefaultTitleColor
            static let pendingSelectedColor: UIColor = .muriel(name: .yellow, .shade30)
            static let approvedSelectedColor: UIColor = .muriel(name: .green, .shade40)
            static let spamSelectedColor: UIColor = .muriel(name: .orange, .shade40)
            static let trashSelectedColor: UIColor = .muriel(name: .red, .shade40)

            static func defaultImageFor(_ buttonType: ModerationButtonType) -> UIImage? {
                return UIImage(systemName: imageNameFor(buttonType))?
                    .withTintColor(imageDefaultTintColor)
                    .withRenderingMode(.alwaysOriginal)
            }

            static func selectedImageFor(_ buttonType: ModerationButtonType) -> UIImage? {
                return UIImage(systemName: imageNameFor(buttonType, selected: true))?
                    .imageWithTintColor(imageTintColorFor(buttonType))
            }

            static func imageNameFor(_ buttonType: ModerationButtonType, selected: Bool = false) -> String {
                let imageName: String = {
                    switch buttonType {
                    case .pending:
                        return pendingImageName
                    case .approved:
                        return approvedImageName
                    case .spam:
                        return spamImageName
                    case .trash:
                        return trashImageName
                    }
                }()

                return selected ? (imageName + ".fill") : imageName
            }

            static func imageTintColorFor(_ buttonType: ModerationButtonType) -> UIColor {
                switch buttonType {
                case .pending:
                    return pendingSelectedColor
                case .approved:
                    return approvedSelectedColor
                case .spam:
                    return spamSelectedColor
                case .trash:
                    return trashSelectedColor
                }
            }
        }
    }
}
