
class ActivityContentStyles: FormattableContentStyles {
    var attributes: [NSAttributedStringKey: Any] {
        return WPStyleGuide.ActivityStyleGuide.contentRegularStyle
    }

    var rangeStylesMap: [NotificationContentRange.Kind: [NSAttributedStringKey: Any]]? {
        return [
            .post: WPStyleGuide.ActivityStyleGuide.contentItalicStyle,
            .comment: WPStyleGuide.ActivityStyleGuide.contentRegularStyle,
            .italic: WPStyleGuide.ActivityStyleGuide.contentItalicStyle
        ]
    }

    let linksColor: UIColor? = WPStyleGuide.ActivityStyleGuide.linkColor
    let quoteStyles: [NSAttributedStringKey: Any]? = nil
    let key: String = "ActivityContentStyles"
}
