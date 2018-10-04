
class RichTextContentStyles: FormattableContentStyles {

    let key: String

    init(key: String) {
        self.key = key
    }

    init() {
        self.key = "RichTextContentStyles"
    }

    var attributes: [NSAttributedString.Key: Any] {
        return WPStyleGuide.Notifications.contentBlockRegularStyle
    }

    var quoteStyles: [NSAttributedString.Key: Any]? {
        return WPStyleGuide.Notifications.contentBlockBoldStyle
    }

    var rangeStylesMap: [FormattableRangeKind: [NSAttributedString.Key: Any]]? {
        return [
            .blockquote: WPStyleGuide.Notifications.contentBlockQuotedStyle,
            .noticon: WPStyleGuide.Notifications.blockNoticonStyle,
            .match: WPStyleGuide.Notifications.contentBlockMatchStyle
        ]
    }

    var linksColor: UIColor? {
        return WPStyleGuide.Notifications.blockLinkColor
    }
}
