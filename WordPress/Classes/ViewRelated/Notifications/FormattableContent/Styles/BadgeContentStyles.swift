
class BadgeContentStyles: FormattableContentStyles {

    let key: String

    init(cachingKey: String) {
        key = cachingKey
    }

    var attributes: [NSAttributedString.Key: Any] {
        return WPStyleGuide.Notifications.badgeRegularStyle
    }

    var quoteStyles: [NSAttributedString.Key: Any]? {
        return WPStyleGuide.Notifications.badgeBoldStyle
    }

    var rangeStylesMap: [FormattableRangeKind: [NSAttributedString.Key: Any]]? {
        return [
            .user: WPStyleGuide.Notifications.badgeBoldStyle,
            .post: WPStyleGuide.Notifications.badgeItalicsStyle,
            .comment: WPStyleGuide.Notifications.badgeItalicsStyle,
            .blockquote: WPStyleGuide.Notifications.badgeQuotedStyle
        ]
    }

    var linksColor: UIColor? {
        return WPStyleGuide.Notifications.badgeLinkColor
    }
}
