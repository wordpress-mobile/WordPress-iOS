import Foundation

public protocol FormattableContentRange {
    typealias Shift = Int
    var kind: FormattableRangeKind { get }
    var range: NSRange { get }
    func apply(_ styles: FormattableContentStyles, to string: NSMutableAttributedString, withShift shift: Int) -> Shift
}

extension FormattableContentRange {
    func rangeShifted(by shift: Int) -> NSRange {
        return NSMakeRange(range.location + shift, range.length)
    }

    func apply(_ styles: FormattableContentStyles, to string: NSMutableAttributedString, at shiftedRange: NSRange) {
        if let rangeStyle = styles.rangeStylesMap?[kind] {
            string.addAttributes(rangeStyle, range: shiftedRange)
        }
    }
}

public extension FormattableContentRange where Self: LinkContentRange {
    public func apply(_ styles: FormattableContentStyles, to string: NSMutableAttributedString, withShift shift: Int) -> Shift {
        let shiftedRange = rangeShifted(by: shift)

        apply(styles, to: string, at: shiftedRange)
        applyURLStyles(styles, to: string, shiftedRange: shiftedRange)

        return 0
    }
}

public protocol LinkContentRange {
    var url: URL? { get }
    func applyURLStyles(_ styles: FormattableContentStyles, to string: NSMutableAttributedString, shiftedRange: NSRange)
}

extension LinkContentRange where Self: FormattableContentRange {
    public func applyURLStyles(_ styles: FormattableContentStyles, to string: NSMutableAttributedString, shiftedRange: NSRange) {
        if let url = url, let linksColor = styles.linksColor {
            string.addAttribute(.link, value: url, range: shiftedRange)
            string.addAttribute(.foregroundColor, value: linksColor, range: shiftedRange)
        }
    }
}

// MARK: - DefaultFormattableContentRange Entity
//
public class NotificationContentRange: FormattableContentRange, LinkContentRange {
    public let kind: FormattableRangeKind
    public let range: NSRange

    public let userID: NSNumber?
    public let siteID: NSNumber?
    public let postID: NSNumber?
    public let url: URL?

    public init(kind: FormattableRangeKind, properties: Properties) {
        self.kind = kind
        range = properties.range
        url = properties.url
        siteID = properties.siteID
        userID = properties.userID
        postID = properties.postID
    }
}

public struct FormattableRangeKind: Hashable {
    let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

public class FormattableCommentRange: NotificationContentRange {
    public let commentID: NSNumber?

    public init(commentID: NSNumber?, properties: Properties) {
        self.commentID = commentID
        super.init(kind: .comment, properties: properties)
    }
}

public class FormattableNoticonRange: FormattableContentRange {
    public var kind: FormattableRangeKind = .noticon
    public var range: NSRange
    public let value: String

    private var noticon: String {
        return value + " "
    }

    public init(value: String, range: NSRange) {
        self.value = value
        self.range = range
    }

    public func apply(_ styles: FormattableContentStyles, to string: NSMutableAttributedString, withShift shift: Int) -> FormattableContentRange.Shift {
        let shiftedRange = rangeShifted(by: shift)
        insertIcon(to: string, at: shiftedRange)

        let longerRange = NSMakeRange(shiftedRange.location, shiftedRange.length + noticon.count)
        apply(styles, to: string, at: longerRange)

        return noticon.count
    }

    func insertIcon(to string: NSMutableAttributedString, at shiftedRange: NSRange) {
        string.replaceCharacters(in: shiftedRange, with: noticon)
    }
}

extension NotificationContentRange {
    public struct Properties {
        let range: NSRange
        public var url: URL?
        public var siteID: NSNumber?
        public var userID: NSNumber?
        public var postID: NSNumber?

        public init(range: NSRange) {
            self.range = range
        }
    }
}

extension FormattableRangeKind {
    public static let user       = FormattableRangeKind("user")
    public static let post       = FormattableRangeKind("post")
    public static let comment    = FormattableRangeKind("comment")
    public static let stats      = FormattableRangeKind("stat")
    public static let follow     = FormattableRangeKind("follow")
    public static let blockquote = FormattableRangeKind("blockquote")
    public static let noticon    = FormattableRangeKind("noticon")
    public static let site       = FormattableRangeKind("site")
    public static let match      = FormattableRangeKind("match")
    public static let link       = FormattableRangeKind("link")
    public static let italic     = FormattableRangeKind("i")
}
