
import Foundation

extension FormattableRangeKind {
    static let `default` = FormattableRangeKind("default")
    static let theme = FormattableRangeKind("theme")
    static let plugin = FormattableRangeKind("plugin")
}

class ActivityRange: FormattableContentRange, LinkContentRange {
    var range: NSRange

    var kind: FormattableRangeKind {
        return internalKind ?? .default
    }

    var url: URL? {
        return internalUrl
    }

    private var internalUrl: URL?
    private var internalKind: FormattableRangeKind?

    init(kind: FormattableRangeKind? = nil, range: NSRange, url: URL?) {
        self.range = range
        self.internalUrl = url
        self.internalKind = kind
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

class ActivityCommentRange: ActivityRange {
    override var kind: FormattableRangeKind {
        return .comment
    }
}

class ActivityThemeRange: ActivityRange {
    override var kind: FormattableRangeKind {
        return .theme
    }
}

class ActivityPluginRange: ActivityRange {
    init(range: NSRange, pluginSlug: String, siteSlug: String) {
        let url = ActivityPluginRange.urlWith(pluginSlug: pluginSlug, siteSlug: siteSlug)
        super.init(kind: .plugin, range: range, url: url)
    }

    private static func urlWith(pluginSlug: String, siteSlug: String) -> URL? {
        let urlString = "https://wordpress.com/plugins/\(pluginSlug)/\(siteSlug)"
        return URL(string: urlString)
    }
}
