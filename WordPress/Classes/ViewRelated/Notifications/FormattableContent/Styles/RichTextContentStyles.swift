
class RichTextContentStyles: FormattableContentStyles {

    let key: String

    init(key: String) {
        self.key = key
    }

    init() {
        self.key = "RichTextContentStyles"
    }

    var attributes: [NSAttributedStringKey : Any] {
        return WPStyleGuide.Notifications.contentBlockRegularStyle
    }

    var quoteStyles: [NSAttributedStringKey : Any]? {
        return WPStyleGuide.Notifications.contentBlockBoldStyle
    }

    var rangeStylesMap: [FormattableContentRange.Kind : [NSAttributedStringKey : Any]]? {
        return [
            .Blockquote: WPStyleGuide.Notifications.contentBlockQuotedStyle,
            .Noticon: WPStyleGuide.Notifications.blockNoticonStyle,
            .Match: WPStyleGuide.Notifications.contentBlockMatchStyle
        ]
    }

    var linksColor: UIColor? {
        return WPStyleGuide.Notifications.blockLinkColor
    }
}
