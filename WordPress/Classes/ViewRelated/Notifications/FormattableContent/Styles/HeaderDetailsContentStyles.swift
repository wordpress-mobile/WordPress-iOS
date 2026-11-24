import FormattableContentKit
import WordPressShared

class HeaderDetailsContentStyles: FormattableContentStyles {
    var attributes: [NSAttributedString.Key: Any] {
        WPStyleGuide.Notifications.headerDetailsRegularStyle(for: horizontalSizeClass)
    }

    var quoteStyles: [NSAttributedString.Key: Any]?

    var rangeStylesMap: [FormattableRangeKind: [NSAttributedString.Key: Any]]?

    var linksColor: UIColor?

    let key: String

    private let horizontalSizeClass: UIUserInterfaceSizeClass

    /// - Parameter horizontalSizeClass: The horizontal size class of the window that displays the header.
    init(horizontalSizeClass: UIUserInterfaceSizeClass) {
        self.horizontalSizeClass = horizontalSizeClass
        self.key = WPStyleGuide.Notifications.cacheKey("HeaderDetailsContentStyles", for: horizontalSizeClass)
    }
}
