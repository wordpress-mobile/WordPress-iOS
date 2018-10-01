
class ActivityContentStyles: FormattableContentStyles {
    var attributes: [NSAttributedString.Key: Any] {
        return WPStyleGuide.ActivityStyleGuide.contentRegularStyle
    }

    var rangeStylesMap: [FormattableRangeKind: [NSAttributedString.Key: Any]]? {
        return [
            .post: WPStyleGuide.ActivityStyleGuide.contentItalicStyle,
            .comment: WPStyleGuide.ActivityStyleGuide.contentRegularStyle,
            .italic: WPStyleGuide.ActivityStyleGuide.contentItalicStyle
        ]
    }

    let linksColor: UIColor? = WPStyleGuide.ActivityStyleGuide.linkColor
    let quoteStyles: [NSAttributedString.Key: Any]? = nil
    let key: String = "ActivityContentStyles"
}
