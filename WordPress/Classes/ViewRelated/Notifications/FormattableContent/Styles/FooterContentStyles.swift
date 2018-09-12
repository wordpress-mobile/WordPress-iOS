
class FooterContentStyles: FormattableContentStyles {
    var attributes: [NSAttributedString.Key: Any] {
        return WPStyleGuide.Notifications.footerRegularStyle
    }

    var quoteStyles: [NSAttributedString.Key: Any]? = nil

    var rangeStylesMap: [FormattableRangeKind: [NSAttributedString.Key: Any]]? {
        return [
            .noticon: WPStyleGuide.Notifications.blockNoticonStyle
        ]
    }

    var linksColor: UIColor? = nil

    var key: String = "FooterContentStyles"
}
