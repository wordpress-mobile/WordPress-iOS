import FormattableContentKit
import WordPressShared

class HeaderContentStyles: FormattableContentStyles {
    var attributes: [NSAttributedString.Key: Any] {
        WPStyleGuide.Notifications.headerTitleRegularStyle(for: horizontalSizeClass)
    }

    var quoteStyles: [NSAttributedString.Key: Any]?

    var rangeStylesMap: [FormattableRangeKind: [NSAttributedString.Key: Any]]? {
        [
            .user: WPStyleGuide.Notifications.headerTitleBoldStyle(for: horizontalSizeClass),
            .post: WPStyleGuide.Notifications.headerTitleContextStyle(for: horizontalSizeClass),
            .comment: WPStyleGuide.Notifications.headerTitleContextStyle(for: horizontalSizeClass)
        ]
    }

    var linksColor: UIColor?

    let key: String

    private let horizontalSizeClass: UIUserInterfaceSizeClass

    /// - Parameter horizontalSizeClass: The horizontal size class of the window that displays the header.
    init(horizontalSizeClass: UIUserInterfaceSizeClass) {
        self.horizontalSizeClass = horizontalSizeClass
        self.key = WPStyleGuide.Notifications.cacheKey("HeaderContentStyles", for: horizontalSizeClass)
    }
}
