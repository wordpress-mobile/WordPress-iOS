
class SubjectContentStyles: FormattableContentStyles {
    var attributes: [NSAttributedStringKey : Any] {
        return WPStyleGuide.Notifications.subjectRegularStyle
    }

    var quoteStyles: [NSAttributedStringKey : Any]? {
        return WPStyleGuide.Notifications.subjectItalicsStyle
    }

    var rangeStylesMap: [FormattableContentRange.Kind : [NSAttributedStringKey : Any]]? {
        return [
            .User: WPStyleGuide.Notifications.subjectBoldStyle,
            .Post: WPStyleGuide.Notifications.subjectItalicsStyle,
            .Comment: WPStyleGuide.Notifications.subjectItalicsStyle,
            .Blockquote: WPStyleGuide.Notifications.subjectQuotedStyle,
            .Noticon: WPStyleGuide.Notifications.subjectNoticonStyle
        ]
    }

    var linksColor: UIColor? = nil
    var key: String = "SubjectContentStyles"
}
