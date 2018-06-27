
class HeaderContentStyles: FormattableContentStyles {
    var attributes: [NSAttributedStringKey : Any] {
        return WPStyleGuide.Notifications.headerTitleRegularStyle
    }

    var quoteStyles: [NSAttributedStringKey : Any]? = nil

    var rangeStylesMap: [FormattableContentRange.Kind : [NSAttributedStringKey : Any]]? {
        return [
            .User: WPStyleGuide.Notifications.headerTitleBoldStyle,
            .Post: WPStyleGuide.Notifications.headerTitleContextStyle,
            .Comment: WPStyleGuide.Notifications.headerTitleContextStyle
        ]
    }

    var linksColor: UIColor? = nil

    var key: String = "HeaderContentStyles"
}
