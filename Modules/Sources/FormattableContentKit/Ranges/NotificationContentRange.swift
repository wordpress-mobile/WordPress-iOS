import Foundation

public class NotificationContentRange: FormattableContentRange, LinkContentRange {
    public let kind: FormattableRangeKind
    public let range: NSRange

    public let userID: NSNumber?
    public let siteID: NSNumber?
    public let postID: NSNumber?
    public let streamKey: String?
    public let url: URL?

    public init(kind: FormattableRangeKind, properties: Properties) {
        self.kind = kind
        range = properties.range
        url = properties.url
        siteID = properties.siteID
        userID = properties.userID
        postID = properties.postID
        streamKey = properties.streamKey
    }
}

extension NotificationContentRange {
    public struct Properties {
        let range: NSRange
        public var url: URL?
        public var siteID: NSNumber?
        public var userID: NSNumber?
        public var postID: NSNumber?
        public var streamKey: String?

        public init(range: NSRange) {
            self.range = range
        }
    }
}
