import WordPressShared

class SnippetsContentStyles: FormattableContentStyles {
    var attributes: [NSAttributedString.Key: Any] {
        return WPStyleGuide.Notifications.snippetRegularStyle
    }

    var quoteStyles: [NSAttributedString.Key: Any]? = nil

    var rangeStylesMap: [FormattableRangeKind: [NSAttributedString.Key: Any]]? = nil

    var linksColor: UIColor? = nil

    var key: String = "SnipetsContentStyles"
}
