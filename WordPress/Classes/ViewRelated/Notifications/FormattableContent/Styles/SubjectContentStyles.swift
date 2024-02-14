import WordPressShared

class SubjectContentStyles: FormattableContentStyles {
    var attributes: [NSAttributedString.Key: Any] {
        return WPStyleGuide.Notifications.subjectRegularStyle
    }

    var quoteStyles: [NSAttributedString.Key: Any]? {
        return WPStyleGuide.Notifications.subjectItalicsStyle
    }

    var rangeStylesMap: [FormattableRangeKind: [NSAttributedString.Key: Any]]? {
        return [
            .user: WPStyleGuide.Notifications.subjectRegularStyle,
            .post: WPStyleGuide.Notifications.subjectRegularStyle,
            .site: WPStyleGuide.Notifications.subjectRegularStyle,
            .comment: WPStyleGuide.Notifications.subjectRegularStyle,
            .blockquote: WPStyleGuide.Notifications.subjectQuotedStyle,
            .noticon: WPStyleGuide.Notifications.subjectNoticonStyle
        ]
    }

    var linksColor: UIColor? = nil
    var key: String = "SubjectContentStyles"
}
