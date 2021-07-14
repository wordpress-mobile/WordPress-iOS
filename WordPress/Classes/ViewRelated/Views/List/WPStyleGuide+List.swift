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
        public static let snippetFont = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .regular)
        public static let snippetTextColor = UIColor.textSubtle
    }
}
