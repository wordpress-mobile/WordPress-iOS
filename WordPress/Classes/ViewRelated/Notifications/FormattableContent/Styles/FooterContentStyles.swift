import FormattableContentKit
import WordPressShared

class FooterContentStyles: FormattableContentStyles {
    var attributes: [NSAttributedString.Key: Any] {
        WPStyleGuide.Notifications.footerRegularStyle(for: horizontalSizeClass)
    }

    var quoteStyles: [NSAttributedString.Key: Any]?

    var rangeStylesMap: [FormattableRangeKind: [NSAttributedString.Key: Any]]? {
        [
            .noticon: WPStyleGuide.Notifications.blockNoticonStyle(for: horizontalSizeClass)
        ]
    }

    var linksColor: UIColor?

    let key: String

    private let horizontalSizeClass: UIUserInterfaceSizeClass

    /// - Parameter horizontalSizeClass: The horizontal size class of the window that displays the footer.
    init(horizontalSizeClass: UIUserInterfaceSizeClass) {
        self.horizontalSizeClass = horizontalSizeClass
        self.key = WPStyleGuide.Notifications.cacheKey("FooterContentStyles", for: horizontalSizeClass)
    }
}
