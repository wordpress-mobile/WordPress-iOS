
import Foundation

extension FormattableRangeKind {
    static let `default` = FormattableRangeKind("default")
}

class ActivityRange: FormattableContentRange, LinkContentRange {
    let kind = FormattableRangeKind.default

    var range: NSRange

    var url: URL? {
        return internalUrl
    }

    private var internalUrl: URL?

    init(range: NSRange, url: URL?) {
        self.range = range
        self.internalUrl = url
    }
}

class ActivityPostRange: FormattableContentRange, LinkContentRange {
    let kind = FormattableRangeKind.post

    var range: NSRange

    let siteID: Int
    let postID: Int

    var url: URL? {
        return URL(string: urlString)
    }

    private var urlString: String {
        return "https://wordpress.com/read/blogs/\(siteID)/posts/\(postID)"
    }

    init(range: NSRange, siteID: Int, postID: Int) {
        self.range = range
        self.siteID = siteID
        self.postID = postID
    }
}
