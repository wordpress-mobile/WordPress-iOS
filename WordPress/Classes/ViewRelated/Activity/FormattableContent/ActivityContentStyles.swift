import FormattableContentKit
import WordPressShared
import WordPressUI

class ActivityContentStyles: FormattableContentStyles {
    var attributes: [NSAttributedString.Key: Any] {
        return contentRegularStyle
    }

    var rangeStylesMap: [FormattableRangeKind: [NSAttributedString.Key: Any]]? {
        return [
            .post: contentItalicStyle,
            .comment: contentRegularStyle,
            .italic: contentItalicStyle
        ]
    }

    let linksColor: UIColor? = UIAppColor.primary
    let quoteStyles: [NSAttributedString.Key: Any]? = nil
    let key: String = "ActivityContentStyles"

    // MARK: - Private Properties

    private var contentRegularStyle: [NSAttributedString.Key: Any] {
        return [
            .paragraphStyle: contentParagraph,
            .font: contentRegularFont,
            .foregroundColor: UIColor.label
        ]
    }

    private var contentItalicStyle: [NSAttributedString.Key: Any] {
        return [
            .paragraphStyle: contentParagraph,
            .font: contentItalicFont,
            .foregroundColor: UIColor.label
        ]
    }

    private var minimumLineHeight: CGFloat {
        return contentFontSize * 1.3
    }

    private var contentParagraph: NSMutableParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = minimumLineHeight
        style.lineBreakMode = .byWordWrapping
        style.alignment = .natural
        return style
    }

    private var contentFontSize: CGFloat {
        return UIFont.preferredFont(forTextStyle: .body).pointSize
    }

    private var contentRegularFont: UIFont {
        return WPStyleGuide.fontForTextStyle(.body)
    }

    private var contentItalicFont: UIFont {
        return WPStyleGuide.fontForTextStyle(.body, symbolicTraits: .traitItalic)
    }
}
