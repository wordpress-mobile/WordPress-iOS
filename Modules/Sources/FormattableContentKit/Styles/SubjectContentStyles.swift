import WordPressShared

public class SubjectContentStyles: FormattableContentStyles {
    public var attributes: [NSAttributedString.Key: Any] {
        return WPStyleGuide.Notifications.subjectRegularStyle
    }

    public var quoteStyles: [NSAttributedString.Key: Any]? {
        return WPStyleGuide.Notifications.subjectItalicsStyle
    }

    public var rangeStylesMap: [FormattableRangeKind: [NSAttributedString.Key: Any]]? {
        return [
            .user: WPStyleGuide.Notifications.subjectSemiBoldStyle,
            .post: WPStyleGuide.Notifications.subjectSemiBoldStyle,
            .site: WPStyleGuide.Notifications.subjectSemiBoldStyle,
            .comment: WPStyleGuide.Notifications.subjectRegularStyle,
            .blockquote: WPStyleGuide.Notifications.subjectQuotedStyle,
            .noticon: WPStyleGuide.Notifications.subjectNoticonStyle
        ]
    }

    public var linksColor: UIColor?
    public var key: String

    public init(linkColor: UIColor? = nil, key: String = "SubjectContentStyles") {
        self.linksColor = linkColor
        self.key = key
    }
}
