
/// Styles definition to be applied to a single FormattableContent entity.
public protocol FormattableContentStyles {
    /// Base attributes applied to the full text.
    var attributes: [NSAttributedString.Key: Any] { get }
    /// Styles to apply to quotes found in the text or nil to not apply any.
    var quoteStyles: [NSAttributedString.Key: Any]? { get }
    /// Styles definition for a specific set of ranges identified by their kind or nil to not apply any.
    var rangeStylesMap: [FormattableRangeKind: [NSAttributedString.Key: Any]]? { get }
    /// Color for text that represent a link or nil to not apply any.
    var linksColor: UIColor? { get }
    /// Key to be used for caching the resulting attributed string. It needs to be unique.
    var key: String { get }
}
