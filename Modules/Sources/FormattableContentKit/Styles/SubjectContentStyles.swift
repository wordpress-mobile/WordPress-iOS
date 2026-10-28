import WordPressShared
import WordPressSharedUI

public class SubjectContentStyles: FormattableContentStyles {
    public var attributes: [NSAttributedString.Key: Any] {
        WPStyleGuide.Notifications.subjectRegularStyle(for: horizontalSizeClass)
    }

    public var quoteStyles: [NSAttributedString.Key: Any]? {
        WPStyleGuide.Notifications.subjectItalicsStyle(for: horizontalSizeClass)
    }

    public var rangeStylesMap: [FormattableRangeKind: [NSAttributedString.Key: Any]]? {
        [
            .user: WPStyleGuide.Notifications.subjectSemiBoldStyle(for: horizontalSizeClass),
            .post: WPStyleGuide.Notifications.subjectSemiBoldStyle(for: horizontalSizeClass),
            .site: WPStyleGuide.Notifications.subjectSemiBoldStyle(for: horizontalSizeClass),
            .comment: WPStyleGuide.Notifications.subjectRegularStyle(for: horizontalSizeClass),
            .blockquote: WPStyleGuide.Notifications.subjectQuotedStyle(for: horizontalSizeClass),
            .noticon: WPStyleGuide.Notifications.subjectNoticonStyle(for: horizontalSizeClass)
        ]
    }

    public var linksColor: UIColor?
    public var key: String

    private let horizontalSizeClass: UIUserInterfaceSizeClass

    /// - Parameter horizontalSizeClass: The horizontal size class of the window that displays the subject.
    public init(
        horizontalSizeClass: UIUserInterfaceSizeClass,
        linkColor: UIColor? = nil,
        key: String = "SubjectContentStyles"
    ) {
        self.horizontalSizeClass = horizontalSizeClass
        self.linksColor = linkColor
        self.key = WPStyleGuide.Notifications.cacheKey(key, for: horizontalSizeClass)
    }
}
