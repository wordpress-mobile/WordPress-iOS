/// Convenience constants catalog related for styling List components.
///
extension WPStyleGuide {
    public enum List {
        // MARK: Section Headers
        public static let sectionHeaderFont = WPStyleGuide.fontForTextStyle(.caption1, fontWeight: .medium)
        public static let sectionHeaderTitleColor = UIColor.textSubtle
        public static let sectionHeaderBackgroundColor = UIColor.basicBackground

        // MARK: Separators
        public static let separatorColor = UIColor.divider

        // MARK: Cells
        public static let placeholderImage = UIImage.gravatarPlaceholderImage
        public static let snippetFont = regularTextFont
        public static let snippetTextColor = UIColor.textSubtle
        public static let plainTitleFont = regularTextFont
        public static let titleTextColor = UIColor.text

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
