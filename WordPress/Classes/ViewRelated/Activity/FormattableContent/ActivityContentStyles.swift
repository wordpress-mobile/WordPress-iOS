
class ActivityContentStyles: FormattableContentStyles {
    var attributes: [NSAttributedStringKey: Any] {
        return WPStyleGuide.ActivityStyleGuide.contentRegularStyle
    }

    var quoteStyles: [NSAttributedStringKey: Any]? = nil

    var rangeStylesMap: [NotificationContentRange.Kind: [NSAttributedStringKey: Any]]? {
        return [
            .post: WPStyleGuide.ActivityStyleGuide.contentItalicStyle,
            .comment: WPStyleGuide.ActivityStyleGuide.contentItalicStyle,
        ]
    }

    var linksColor: UIColor? = WPStyleGuide.ActivityStyleGuide.linkColor
    var key: String = "SubjectContentStyles"
}

class ItalicContentRange: FormattableContentRange {
    var url: URL?
    let range: NSRange

    public init(range: NSRange, url: URL?) {
        self.range = range
        self.url = url
    }

    func apply(_ styles: FormattableContentStyles, to string: NSMutableAttributedString, withShift shift: Int) -> FormattableContentRange.Shift {
        return 0
    }
}
