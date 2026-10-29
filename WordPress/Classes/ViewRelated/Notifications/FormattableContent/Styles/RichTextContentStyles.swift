import FormattableContentKit
import WordPressShared

class RichTextContentStyles: FormattableContentStyles {

    let key: String

    private let horizontalSizeClass: UIUserInterfaceSizeClass

    /// - Parameter horizontalSizeClass: The horizontal size class of the window that displays the text.
    init(horizontalSizeClass: UIUserInterfaceSizeClass, key: String = "RichTextContentStyles") {
        self.horizontalSizeClass = horizontalSizeClass
        self.key = WPStyleGuide.Notifications.cacheKey(key, for: horizontalSizeClass)
    }

    var attributes: [NSAttributedString.Key: Any] {
        WPStyleGuide.Notifications.contentBlockRegularStyle(for: horizontalSizeClass)
    }

    var quoteStyles: [NSAttributedString.Key: Any]? {
        WPStyleGuide.Notifications.contentBlockBoldStyle(for: horizontalSizeClass)
    }

    var rangeStylesMap: [FormattableRangeKind: [NSAttributedString.Key: Any]]? {
        [
            .blockquote: WPStyleGuide.Notifications.contentBlockQuotedStyle(for: horizontalSizeClass),
            .noticon: WPStyleGuide.Notifications.blockNoticonStyle(for: horizontalSizeClass),
            .match: WPStyleGuide.Notifications.contentBlockMatchStyle(for: horizontalSizeClass)
        ]
    }

    var linksColor: UIColor? {
        WPStyleGuide.Notifications.blockLinkColor
    }
}
