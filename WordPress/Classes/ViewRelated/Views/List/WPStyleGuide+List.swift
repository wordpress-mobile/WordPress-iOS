import UIKit
import WordPressShared

/// Convenience constants catalog related for styling List components.
///
extension WPStyleGuide {
    public enum List {
        // MARK: Section Headers
        public static let sectionHeaderFont = WPStyleGuide.fontForTextStyle(.caption1, fontWeight: .medium)
        public static let sectionHeaderTitleColor = UIColor.secondaryLabel
        public static let sectionHeaderBackgroundColor = UIColor.systemBackground

        // MARK: Separators
        public static let separatorColor = UIColor.separator

        // MARK: Cells
        public static let placeholderImage = UIImage.gravatarPlaceholderImage
        public static let snippetFont = regularTextFont
        public static let snippetTextColor = UIColor.secondaryLabel
        public static let plainTitleFont = regularTextFont
        public static let titleTextColor = UIColor.label

        public static let titleRegularAttributes: [NSAttributedString.Key: Any] = [
            .font: regularTextFont,
            .foregroundColor: titleTextColor
        ]

        public static let titleBoldAttributes: [NSAttributedString.Key: Any] = [
            .font: boldTextFont,
            .foregroundColor: titleTextColor
        ]

        // MARK: Private Styles
        private static let regularTextFont = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .regular)
        private static let boldTextFont = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold)
    }
}
