
class FormattableActivity {
    let activity: Activity

    private let formatter = FormattableContentFormatter()
    private var cachedContentGroup: FormattableContentGroup? = nil

    private var contentGroup: FormattableContentGroup? {
        guard let content = activity.content as? [String: AnyObject], content.isEmpty == false else {
            return nil
        }
        return ActivityContentGroup.create(with: [content])
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

extension Activity: Equatable {
    public static func == (lhs: Activity, rhs: Activity) -> Bool {
        return lhs.activityID == rhs.activityID
    }
}
