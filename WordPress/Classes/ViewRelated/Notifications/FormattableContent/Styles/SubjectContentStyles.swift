
class SubjectContentStyles: FormattableContentStyles {
    var attributes: [NSAttributedStringKey: Any] {
        return WPStyleGuide.Notifications.subjectRegularStyle
    }

    var quoteStyles: [NSAttributedStringKey: Any]? {
        return WPStyleGuide.Notifications.subjectItalicsStyle
    }

    var rangeStylesMap: [NotificationContentRange.Kind: [NSAttributedStringKey: Any]]? {
        return [
            .user: WPStyleGuide.Notifications.subjectBoldStyle,
            .post: WPStyleGuide.Notifications.subjectItalicsStyle,
            .comment: WPStyleGuide.Notifications.subjectItalicsStyle,
            .blockquote: WPStyleGuide.Notifications.subjectQuotedStyle,
            .noticon: WPStyleGuide.Notifications.subjectNoticonStyle
        ]
    }

    var linksColor: UIColor? = nil
    var key: String = "SubjectContentStyles"
}
