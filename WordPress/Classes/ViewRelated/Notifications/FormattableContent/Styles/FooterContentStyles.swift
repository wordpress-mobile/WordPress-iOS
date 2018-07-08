
class FooterContentStyles: FormattableContentStyles {
    var attributes: [NSAttributedStringKey: Any] {
        return WPStyleGuide.Notifications.footerRegularStyle
    }

    var quoteStyles: [NSAttributedStringKey: Any]? = nil

    var rangeStylesMap: [NotificationContentRange.Kind: [NSAttributedStringKey: Any]]? {
        return [
            .noticon: WPStyleGuide.Notifications.blockNoticonStyle
        ]
    }

    var linksColor: UIColor? = nil

    var key: String = "FooterContentStyles"
}
