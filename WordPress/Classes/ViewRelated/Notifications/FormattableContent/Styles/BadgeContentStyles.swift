
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

    var rangeStylesMap: [FormattableContentRange.Kind: [NSAttributedStringKey: Any]]? {
        return [
            .User: WPStyleGuide.Notifications.badgeBoldStyle,
            .Post: WPStyleGuide.Notifications.badgeItalicsStyle,
            .Comment: WPStyleGuide.Notifications.badgeItalicsStyle,
            .Blockquote: WPStyleGuide.Notifications.badgeQuotedStyle
        ]
    }

    var linksColor: UIColor? {
        return WPStyleGuide.Notifications.badgeLinkColor
    }
}
