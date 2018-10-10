
class HeaderContentStyles: FormattableContentStyles {
    var attributes: [NSAttributedString.Key: Any] {
        return WPStyleGuide.Notifications.headerTitleRegularStyle
    }

    var quoteStyles: [NSAttributedString.Key: Any]?

    var rangeStylesMap: [FormattableRangeKind: [NSAttributedString.Key: Any]]? {
        return [
            .user: WPStyleGuide.Notifications.headerTitleBoldStyle,
            .post: WPStyleGuide.Notifications.headerTitleContextStyle,
            .comment: WPStyleGuide.Notifications.headerTitleContextStyle
        ]
    }

    var linksColor: UIColor?

    var key: String = "HeaderContentStyles"
}
