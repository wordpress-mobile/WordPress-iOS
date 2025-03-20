import WordPressShared

public class SnippetsContentStyles: FormattableContentStyles {
    public var attributes: [NSAttributedString.Key: Any] {
        return WPStyleGuide.Notifications.snippetRegularStyle
    }

    public var quoteStyles: [NSAttributedString.Key: Any]?

    public var rangeStylesMap: [FormattableRangeKind: [NSAttributedString.Key: Any]]?

    public var linksColor: UIColor?

    public var key: String

    public init(
        quoteStyles: [NSAttributedString.Key: Any]? = nil,
        rangeStylesMap: [FormattableRangeKind: [NSAttributedString.Key: Any]]? = nil,
        linksColor: UIColor? = nil,
        key: String = "SnippetsContentStyles"
    ) {
        self.quoteStyles = quoteStyles
        self.rangeStylesMap = rangeStylesMap
        self.linksColor = linksColor
        self.key = key
    }
}
