import WordPressShared

class SnippetsContentStyles: FormattableContentStyles {
    var attributes: [NSAttributedString.Key: Any] {
        return WPStyleGuide.Notifications.snippetRegularStyle
    }

    var quoteStyles: [NSAttributedString.Key: Any]?

    var rangeStylesMap: [FormattableRangeKind: [NSAttributedString.Key: Any]]?

    var linksColor: UIColor?

    var key: String = "SnippetsContentStyles"
}
