
class BadgeContentStyles: FormattableContentStyles {

    let key: String

    init(cachingKey: String) {
        key = cachingKey
    }

    var attributes: [NSAttributedStringKey: Any] {
        return WPStyleGuide.Notifications.badgeRegularStyle
    }

    var quoteStyles: [NSAttributedStringKey: Any]? {
        return WPStyleGuide.Notifications.badgeBoldStyle
    }

    var rangeStylesMap: [FormattableRangeKind: [NSAttributedStringKey: Any]]? {
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
