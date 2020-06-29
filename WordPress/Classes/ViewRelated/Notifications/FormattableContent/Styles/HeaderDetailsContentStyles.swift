class HeaderDetailsContentStyles: FormattableContentStyles {
    var attributes: [NSAttributedString.Key: Any] {
        return WPStyleGuide.Notifications.headerDetailsRegularStyle
    }

    var quoteStyles: [NSAttributedString.Key: Any]?

    var rangeStylesMap: [FormattableRangeKind: [NSAttributedString.Key: Any]]?

    var linksColor: UIColor?

    var key: String = "HeaderDetailsContentStyles"
}
