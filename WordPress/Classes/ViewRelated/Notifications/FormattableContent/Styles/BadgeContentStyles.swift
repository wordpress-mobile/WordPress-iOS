import FormattableContentKit
import WordPressShared

class BadgeContentStyles: FormattableContentStyles {

    let key: String
    let isTitle: Bool

    private let horizontalSizeClass: UIUserInterfaceSizeClass

    /// - Parameter horizontalSizeClass: The horizontal size class of the window that displays the badge.
    init(cachingKey: String, isTitle: Bool, horizontalSizeClass: UIUserInterfaceSizeClass) {
        key = WPStyleGuide.Notifications.cacheKey(cachingKey, for: horizontalSizeClass)
        self.isTitle = isTitle
        self.horizontalSizeClass = horizontalSizeClass
    }

    var attributes: [NSAttributedString.Key: Any] {
        if isTitle {
            return WPStyleGuide.Notifications.badgeTitleStyle(for: horizontalSizeClass)
        }

        return WPStyleGuide.Notifications.badgeRegularStyle(for: horizontalSizeClass)
    }

    var quoteStyles: [NSAttributedString.Key: Any]? {
        if isTitle {
            return WPStyleGuide.Notifications.badgeTitleBoldStyle(for: horizontalSizeClass)
        }

        return WPStyleGuide.Notifications.badgeBoldStyle(for: horizontalSizeClass)
    }

    var rangeStylesMap: [FormattableRangeKind: [NSAttributedString.Key: Any]]? {
        if isTitle {
            return [
                .user: WPStyleGuide.Notifications.badgeTitleBoldStyle(for: horizontalSizeClass),
                .post: WPStyleGuide.Notifications.badgeTitleItalicsStyle(for: horizontalSizeClass),
                .comment: WPStyleGuide.Notifications.badgeTitleItalicsStyle(for: horizontalSizeClass),
                .blockquote: WPStyleGuide.Notifications.badgeTitleQuotedStyle(for: horizontalSizeClass),
                .site: WPStyleGuide.Notifications.badgeTitleBoldStyle(for: horizontalSizeClass),
                .strong: WPStyleGuide.Notifications.badgeTitleBoldStyle(for: horizontalSizeClass)
            ]
        }

        return [
            .user: WPStyleGuide.Notifications.badgeBoldStyle(for: horizontalSizeClass),
            .post: WPStyleGuide.Notifications.badgeItalicsStyle(for: horizontalSizeClass),
            .comment: WPStyleGuide.Notifications.badgeItalicsStyle(for: horizontalSizeClass),
            .blockquote: WPStyleGuide.Notifications.badgeQuotedStyle(for: horizontalSizeClass),
            .site: WPStyleGuide.Notifications.badgeBoldStyle(for: horizontalSizeClass)
        ]
    }

    var linksColor: UIColor? {
        WPStyleGuide.Notifications.badgeLinkColor
    }
}
