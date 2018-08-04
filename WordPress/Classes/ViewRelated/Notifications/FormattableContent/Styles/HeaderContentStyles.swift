
class HeaderContentStyles: FormattableContentStyles {
    var attributes: [NSAttributedStringKey: Any] {
        return WPStyleGuide.Notifications.headerTitleRegularStyle
    }

    var quoteStyles: [NSAttributedStringKey: Any]? = nil

    var rangeStylesMap: [FormattableRangeKind: [NSAttributedStringKey: Any]]? {
        return [
            .user: WPStyleGuide.Notifications.headerTitleBoldStyle,
            .post: WPStyleGuide.Notifications.headerTitleContextStyle,
            .comment: WPStyleGuide.Notifications.headerTitleContextStyle
        ]
    }

    var linksColor: UIColor? = nil

    var key: String = "HeaderContentStyles"
}
