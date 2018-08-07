
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
