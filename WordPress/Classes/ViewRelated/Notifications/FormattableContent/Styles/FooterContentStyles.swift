
class FooterContentStyles: FormattableContentStyles {
    var attributes: [NSAttributedStringKey : Any] {
        return WPStyleGuide.Notifications.footerRegularStyle
    }

    var quoteStyles: [NSAttributedStringKey : Any]? = nil

    var rangeStylesMap: [FormattableContentRange.Kind : [NSAttributedStringKey : Any]]? {
        return [
            .Noticon: WPStyleGuide.Notifications.blockNoticonStyle
        ]
    }

    var linksColor: UIColor? = nil

    var key: String = "FooterContentStyles"
}
