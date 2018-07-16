
class FormattableActivity {
    let activity: Activity

    private let formatter = FormattableContentFormatter()
    private var cachedContentGroup: FormattableContentGroup? = nil

    private var contentGroup: FormattableContentGroup? {
        guard let content = activity.content as? [String: AnyObject], content.isEmpty == false else {
            return nil
        }
        return ActivityContentGroup.create(with: [content], parent: self)
    }

    init(with activity: Activity) {
        self.activity = activity
    }

    func formattedContent(using styles: FormattableContentStyles) -> NSAttributedString {
        guard let textBlock: FormattableTextContent = contentGroup?.blockOfKind(.text) else {
            return NSAttributedString()
        }
        return formatter.render(content: textBlock, with: styles)
    }

    func range(with url: URL) -> FormattableContentRange? {
        let rangesWithURL = contentGroup?.blocks.compactMap {
            $0.range(with: url)
        }
        return rangesWithURL?.first
    }
}

extension FormattableActivity: FormattableContentParent {
    public func isEqual(to other: FormattableContentParent) -> Bool {
        guard let otherActivity = other as? FormattableActivity else {
            return false
        }
        return self.activity == otherActivity.activity
    }

    public var metaCommentID: NSNumber? {
        return 0
    }

    public var uniqueID: String? {
        return activity.activityID
    }

    public var kind: ParentKind {
        return .Unknown
    }

    public var metaReplyID: NSNumber? {
        return 0
    }

    public var isPingback: Bool {
        return false
    }

    public func didChangeOverrides() {

    }
}

extension Activity: Equatable {
    public static func == (lhs: Activity, rhs: Activity) -> Bool {
        return lhs.activityID == rhs.activityID
    }
}
