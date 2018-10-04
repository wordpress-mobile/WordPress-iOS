
class FooterContentStyles: FormattableContentStyles {
    var attributes: [NSAttributedString.Key: Any] {
        return WPStyleGuide.Notifications.footerRegularStyle
    }

    var quoteStyles: [NSAttributedString.Key: Any]?

    var rangeStylesMap: [FormattableRangeKind: [NSAttributedString.Key: Any]]? {
        return [
            .noticon: WPStyleGuide.Notifications.blockNoticonStyle
        ]
    }

    var linksColor: UIColor?

    var key: String = "FooterContentStyles"
}
