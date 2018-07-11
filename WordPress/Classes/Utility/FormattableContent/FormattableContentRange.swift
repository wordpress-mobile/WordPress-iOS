import Foundation

public protocol FormattableContentRange {
    typealias Shift = Int
    var range: NSRange { get }
    func apply(_ styles: FormattableContentStyles, to string: NSMutableAttributedString, withShift shift: Int) -> Shift
}

protocol LinkContentRange {
    var url: URL? { get }
    func applyURLStyles(to string: NSMutableAttributedString, shiftedRange: NSRange, applying styles: FormattableContentStyles)
}

extension LinkContentRange where Self: FormattableContentRange {
    func applyURLStyles(to string: NSMutableAttributedString, shiftedRange: NSRange, applying styles: FormattableContentStyles) {
        if let url = url, let linksColor = styles.linksColor {
            string.addAttribute(.link, value: url, range: shiftedRange)
            string.addAttribute(.foregroundColor, value: linksColor, range: shiftedRange)
        }
    }
}

// MARK: - DefaultFormattableContentRange Entity
//
public class NotificationContentRange: FormattableContentRange, LinkContentRange {
    public let kind: Kind
    public let range: NSRange

    public let userID: NSNumber?
    public let siteID: NSNumber?
    public let postID: NSNumber?
    public let url: URL?

    public init(kind: Kind, properties: Properties) {
        self.kind = kind
        range = properties.range
        url = properties.url
        siteID = properties.siteID
        userID = properties.userID
        postID = properties.postID
    }

    public func apply(_ styles: FormattableContentStyles, to string: NSMutableAttributedString, withShift shift: Int) -> Shift {
        let shiftedRange = rangeShifted(by: shift)

        apply(styles, to: string, at: shiftedRange)
        applyURLStyles(to: string, shiftedRange: shiftedRange, applying: styles)

        return 0
    }

    fileprivate func apply(_ styles: FormattableContentStyles, to string: NSMutableAttributedString, at shiftedRange: NSRange) {
        if let rangeStyle = styles.rangeStylesMap?[kind] {
            string.addAttributes(rangeStyle, range: shiftedRange)
        }
    }

    fileprivate func rangeShifted(by shift: Int) -> NSRange {
        return NSMakeRange(range.location + shift, range.length)
    }
}

public extension NotificationContentRange {
    public struct Kind: Equatable, Hashable {
        let rawType: String

        public init(_ rawType: String) {
            self.rawType = rawType
        }
    }
}

public class FormattableCommentRange: NotificationContentRange {
    public let commentID: NSNumber?

    public init(commentID: NSNumber?, properties: Properties) {
        self.commentID = commentID
        super.init(kind: .comment, properties: properties)
    }
}

public class FormattableNoticonRange: NotificationContentRange {
    public let value: String

    private var noticon: String {
        return value + " "
    }

    public init(value: String, properties: Properties) {
        self.value = value
        super.init(kind: .noticon, properties: properties)
    }

    public override func apply(_ styles: FormattableContentStyles, to string: NSMutableAttributedString, withShift shift: Int) -> Shift {

        let shiftedRange = rangeShifted(by: shift)
        string.replaceCharacters(in: shiftedRange, with: noticon)

        let superShift = super.apply(styles, to: string, withShift: shift)

        return noticon.count + superShift
    }

    override func apply(_ styles: FormattableContentStyles, to string: NSMutableAttributedString, at shiftedRange: NSRange) {
        let longerRange = NSMakeRange(shiftedRange.location, shiftedRange.length + noticon.count)
        super.apply(styles, to: string, at: longerRange)
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

public extension NotificationContentRange.Kind {
    public static let user       = NotificationContentRange.Kind("user")
    public static let post       = NotificationContentRange.Kind("post")
    public static let comment    = NotificationContentRange.Kind("comment")
    public static let stats      = NotificationContentRange.Kind("stat")
    public static let follow     = NotificationContentRange.Kind("follow")
    public static let blockquote = NotificationContentRange.Kind("blockquote")
    public static let noticon    = NotificationContentRange.Kind("noticon")
    public static let site       = NotificationContentRange.Kind("site")
    public static let match      = NotificationContentRange.Kind("match")
    public static let link       = NotificationContentRange.Kind("link")
    public static let italic     = NotificationContentRange.Kind("i")
}
