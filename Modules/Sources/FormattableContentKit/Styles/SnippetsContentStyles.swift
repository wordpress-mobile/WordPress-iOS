import WordPressShared
import WordPressSharedUI

public class SnippetsContentStyles: FormattableContentStyles {
    public var attributes: [NSAttributedString.Key: Any] {
        WPStyleGuide.Notifications.snippetRegularStyle(for: horizontalSizeClass)
    }

    public var quoteStyles: [NSAttributedString.Key: Any]?

    public var rangeStylesMap: [FormattableRangeKind: [NSAttributedString.Key: Any]]?

    public var linksColor: UIColor?

    public var key: String

    private let horizontalSizeClass: UIUserInterfaceSizeClass

    /// - Parameter horizontalSizeClass: The horizontal size class of the window that displays the snippet.
    public init(
        horizontalSizeClass: UIUserInterfaceSizeClass,
        quoteStyles: [NSAttributedString.Key: Any]? = nil,
        rangeStylesMap: [FormattableRangeKind: [NSAttributedString.Key: Any]]? = nil,
        linksColor: UIColor? = nil,
        key: String = "SnippetsContentStyles"
    ) {
        self.horizontalSizeClass = horizontalSizeClass
        self.quoteStyles = quoteStyles
        self.rangeStylesMap = rangeStylesMap
        self.linksColor = linksColor
        self.key = WPStyleGuide.Notifications.cacheKey(key, for: horizontalSizeClass)
    }
}
