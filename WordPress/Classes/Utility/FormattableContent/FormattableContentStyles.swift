
public protocol FormattableContentStyles {
    var attributes: [NSAttributedStringKey: Any] { get }
    var quoteStyles: [NSAttributedStringKey: Any]? { get }
    var rangeStylesMap: [NotificationContentRange.Kind: [NSAttributedStringKey: Any]]? { get }
    var linksColor: UIColor? { get }
    var key: String { get }
}
