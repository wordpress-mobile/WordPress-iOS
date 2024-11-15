import Foundation
import WordPressShared
import Gridicons

/// A WPStyleGuide extension with styles and methods specific to the Reader feature.
///
extension WPStyleGuide {
    // MARK: - Original Post/Site Attribution Styles.

    @objc public class func originalAttributionParagraphAttributes() -> [NSAttributedString.Key: Any] {
        let font = WPStyleGuide.fontForTextStyle(originalAttributionTextStyle())

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = Cards.defaultLineSpacing

        return [
            .paragraphStyle: paragraphStyle,
            .font: font,
        ]
    }

    @objc public class func originalAttributionTextStyle() -> UIFont.TextStyle {
        return Cards.contentTextStyle
    }

    // MARK: - Apply Card Styles

    public class func applyReaderCardAttributionLabelStyle(_ label: UILabel) {
        label.textColor = UIColor(
            light: UIAppColor.gray(.shade80),
            dark: .secondaryLabel
        )
    }

    // MARK: - Apply Stream Header Styles

    @objc public class func applyReaderStreamHeaderTitleStyle(_ label: UILabel) {
        label.font = WPStyleGuide.fontForTextStyle(.title1, fontWeight: .bold)
        label.textColor = .label
    }

    // MARK: - Button Styles and Text
    class func applyReaderActionButtonStyle(_ button: UIButton,
                                            titleColor: UIColor = .secondaryLabel,
                                            imageColor: UIColor = .secondaryLabel,
                                            disabledColor: UIColor = UIAppColor.neutral(.shade10)) {
        button.tintColor = imageColor
        let highlightedColor: UIColor = UIAppColor.neutral
        let selectedColor: UIColor = UIAppColor.primary(.shade40)
        let bothColor: UIColor = UIAppColor.primaryLight

        let highlightedImage = button.image(for: .highlighted)
        let selectedImage = button.image(for: .selected)
        let bothImage = button.image(for: [.highlighted, .selected])
        let disabledImage = button.image(for: .disabled)

        button.setImage(highlightedImage?.imageWithTintColor(highlightedColor), for: .highlighted)
        button.setImage(selectedImage?.imageWithTintColor(selectedColor), for: .selected)
        button.setImage(bothImage?.imageWithTintColor(bothColor), for: [.selected, .highlighted])
        button.setImage(disabledImage?.imageWithTintColor(disabledColor), for: .disabled)

        button.setTitleColor(titleColor, for: .normal)
        button.setTitleColor(highlightedColor, for: .highlighted)
        button.setTitleColor(selectedColor, for: .selected)
        button.setTitleColor(bothColor, for: [.selected, .highlighted])
        button.setTitleColor(disabledColor, for: .disabled)
    }

    class func applyTagsReaderButtonStyle(_ button: UIButton) {
        applyReaderFollowButtonStyle(button)

        button.setTitle(FollowButton.Text.tagsFollowString, for: .normal)
        button.setTitle(FollowButton.Text.tagsFollowingString, for: .selected)
        button.accessibilityLabel = button.isSelected ? FollowButton.Text.tagsFollowingString : FollowButton.Text.tagsFollowString
    }

    @objc public class func applyReaderFollowButtonStyle(_ button: UIButton,
                                                         contentInsets: NSDirectionalEdgeInsets = NSDirectionalEdgeInsets(top: 8.0, leading: 24.0, bottom: 8.0, trailing: 24.0)) {
        let font: UIFont = .preferredFont(forTextStyle: .subheadline)
        button.setTitleColor(.invertedLabel, for: .normal)
        button.setTitleColor(.secondaryLabel, for: .selected)
        button.backgroundColor = button.isSelected ? .clear : .label
        button.layer.borderColor = UIColor.separator.cgColor
        button.layer.cornerRadius = 5.0
        button.titleLabel?.font = font
        button.tintColor = .clear

        button.configuration = .plain()
        button.configuration?.contentInsets = contentInsets
        button.configuration?.titleTextAttributesTransformer = .transformer(with: font)
        applyCommonReaderFollowButtonStyles(button)
    }

    private class func applyCommonReaderFollowButtonStyles(_ button: UIButton) {
        button.setTitle(FollowButton.Text.followStringForDisplay, for: .normal)
        button.setTitle(FollowButton.Text.followingStringForDisplay, for: .selected)

        button.layer.borderWidth = button.isSelected ? 1.0 : 0.0
        // Default accessibility label and hint.
        button.accessibilityLabel = button.isSelected ? FollowButton.Text.followingStringForDisplay : FollowButton.Text.followStringForDisplay
        button.accessibilityHint = FollowButton.Text.accessibilityHint
    }

    // Reader Detail Toolbar Save button
    @objc public class func applyReaderSaveForLaterButtonStyle(_ button: UIButton) {
        button.setImage(ReaderDetail.saveToolbarIcon, for: .normal)
        button.setImage(ReaderDetail.saveSelectedToolbarIcon, for: .selected)
        button.setImage(ReaderDetail.saveSelectedToolbarIcon, for: .highlighted)
        button.setImage(ReaderDetail.saveSelectedToolbarIcon, for: [.highlighted, .selected])

        applyReaderActionButtonStyle(button)
    }

    /// Applies the save for later button style to the button passed as an argument
    /// - Parameter button: the button to apply the style to
    /// - Parameter showTitle: if set to true, will show the button label (default: true)
    @objc public class func applyReaderSaveForLaterButtonTitles(_ button: UIButton, showTitle: Bool = true) {
        let saveTitle = showTitle ? WPStyleGuide.savePostStringForDisplay(false) : ""
        let savedTitle = showTitle ? WPStyleGuide.savePostStringForDisplay(true) : ""

        button.setTitle(saveTitle, for: .normal)
        button.setTitle(savedTitle, for: .selected)
        button.setTitle(savedTitle, for: [.highlighted, .selected])
    }

    /// Applies the reblog button style to the button passed as an argument
    /// - Parameter button: the button to apply the style to
    /// - Parameter showTitle: if set to true, will show the button label (default: true)
    @objc public class func applyReaderReblogActionButtonStyle(_ button: UIButton, showTitle: Bool = true) {
        button.setImage(ReaderDetail.reblogToolbarIcon, for: .normal)

        WPStyleGuide.applyReaderReblogActionButtonTitle(button, showTitle: showTitle)
        WPStyleGuide.applyReaderActionButtonStyle(button)
    }

    /// Applies the reblog button title to the button passed as an argument
    /// - Parameter button: the button to apply the title to
    /// - Parameter showTitle: if  true, will show the button label (default: true), if false, the label will be empty (button with no label)
    @objc public class func applyReaderReblogActionButtonTitle(_ button: UIButton, showTitle: Bool = true) {
        let title = showTitle ? NSLocalizedString("Reblog", comment: "Text for the 'Reblog' button.") : ""
        button.setTitle(title, for: .normal)
        button.setTitle(title, for: .highlighted)
    }

    @objc public class func likeCountForDisplay(_ count: Int) -> String {
        let likeStr = NSLocalizedString("Like", comment: "Text for the 'like' button. Tapping marks a post in the reader as 'liked'.")
        let likesStr = NSLocalizedString("Likes", comment: "Text for the 'like' button. Tapping removes the 'liked' status from a post.")

        if count == 1 {
            return "\(count) \(likeStr)"
        } else {
            return "\(count) \(likesStr)"
        }
    }

    @objc public class func commentCountForDisplay(_ count: Int) -> String {
        let commentStr = NSLocalizedString("Comment", comment: "Text for the 'comment' when there is 1 or 0 comments")
        let commentsStr = NSLocalizedString("Comments", comment: "Text for the 'comment' button when there are multiple comments")

        if count == 1 {
            return "\(count) \(commentStr)"
        } else {
            return "\(count) \(commentsStr)"
        }
    }

    @objc public class func savePostStringForDisplay(_ isSaved: Bool) -> String {
        if isSaved {
            return NSLocalizedString("Saved", comment: "Title of action button for a Reader post that has been saved to read later.")
        } else {
            return NSLocalizedString("Save", comment: "Title of action button to save a Reader post to read later.")
        }
    }

    // MARK: - Gap Marker Styles

    @objc public class func applyGapMarkerButtonStyle(_ button: UIButton) {
        button.backgroundColor = gapMarkerButtonBackgroundColor()
        guard let titleLabel = button.titleLabel else {
            return
        }
        WPStyleGuide.configureLabel(titleLabel, textStyle: Cards.loadMoreButtonTextStyle, fontWeight: .semibold)
        button.setTitleColor(UIColor.white, for: UIControl.State())
    }

    @objc public class func gapMarkerButtonBackgroundColor() -> UIColor {
        return UIAppColor.neutral(.shade40)
    }

    @objc public class func gapMarkerButtonBackgroundColorHighlighted() -> UIColor {
        return UIAppColor.primaryLight
    }

    // MARK: - Metrics

    public struct Cards {
        public static let defaultLineSpacing: CGFloat = WPDeviceIdentification.isiPad() ? 6.0 : 3.0
        public static let contentTextStyle: UIFont.TextStyle = .footnote
        public static let buttonTextStyle: UIFont.TextStyle = .subheadline
        public static let loadMoreButtonTextStyle: UIFont.TextStyle = .subheadline
    }

    public struct ReaderDetail {
        public static var reblogToolbarIcon: UIImage? {
            return UIImage(named: "icon-reader-reblog")?.withRenderingMode(.alwaysTemplate)
        }

        static var commentToolbarIcon: UIImage? {
            return UIImage(named: "icon-reader-post-comment")?
                .imageFlippedForRightToLeftLayoutDirection()
                .withRenderingMode(.alwaysTemplate)
        }

        static var commentHighlightedToolbarIcon: UIImage? {
            // note: we don't have a highlighted variant in the new version.
            return commentToolbarIcon
        }

        public static var saveToolbarIcon: UIImage? {
            return UIImage(named: "icon-reader-save-outline")
        }

        public static var saveSelectedToolbarIcon: UIImage? {
            return UIImage(named: "icon-reader-save-fill")
        }

        static var likeToolbarIcon: UIImage? {
            return UIImage(named: "icon-reader-star-outline")?.withRenderingMode(.alwaysTemplate)
        }

        static var likeSelectedToolbarIcon: UIImage? {
            return UIImage(named: "icon-reader-star-fill")?.withRenderingMode(.alwaysTemplate)
        }
    }

    public struct FollowButton {
        struct Text {
            static let accessibilityHint = NSLocalizedString(
                "reader.follow.button.accessibility.hint",
                value: "Follows the tag.",
                comment: "VoiceOver accessibility hint, informing the user the button can be used to follow a tag."
            )
            static let followStringForDisplay =  NSLocalizedString(
                "reader.subscribe.button.title",
                value: "Subscribe",
                comment: "Verb. Button title. Subscribes to a new blog."
            )
            static let followingStringForDisplay = NSLocalizedString(
                "reader.subscribed.button.title",
                value: "Subscribed",
                comment: "Verb. Button title. The user is subscribed to a blog."
            )
            static let tagsFollowString = NSLocalizedString(
                "reader.tags.follow.button.title",
                value: "Follow",
                comment: "Verb. Button title. Follows a new tag."
            )
            static let tagsFollowingString = NSLocalizedString(
                "reader.tags.following.button.title",
                value: "Following",
                comment: "Verb. Button title. The user is following a tag."
            )
        }
    }
}
