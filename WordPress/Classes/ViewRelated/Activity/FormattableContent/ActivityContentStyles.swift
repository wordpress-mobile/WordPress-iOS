
class ActivityContentStyles: FormattableContentStyles {
    var attributes: [NSAttributedStringKey: Any] {
        return WPStyleGuide.ActivityStyleGuide.contentRegularStyle
    }

    var quoteStyles: [NSAttributedStringKey: Any]? = nil

    var rangeStylesMap: [NotificationContentRange.Kind: [NSAttributedStringKey: Any]]? {
        return [
            .post: WPStyleGuide.ActivityStyleGuide.contentItalicStyle,
            .comment: WPStyleGuide.ActivityStyleGuide.contentItalicStyle,
            .italic: WPStyleGuide.ActivityStyleGuide.contentItalicStyle
        ]
    }

    var linksColor: UIColor? = WPStyleGuide.ActivityStyleGuide.linkColor
    var key: String = "ActivityContentStyles"
}
