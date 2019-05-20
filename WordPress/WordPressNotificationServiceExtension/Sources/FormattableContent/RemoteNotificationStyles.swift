import Foundation

import WordPressShared
import WordPressUI

// MARK: - RemoteNotificationStyles

/// Describes how Notifications should appear in the Long Look.
/// Influenced by both SnippetsContentStyles & SubjectContentStyles.
///
class RemoteNotificationStyles: FormattableContentStyles {

    // MARK: Properties

    private lazy var paragraphStyle: NSParagraphStyle = {
        let style = NSMutableParagraphStyle()

        style.alignment          = .natural
        style.lineBreakMode      = .byWordWrapping

        let prevailingLineHeight = UIDevice.isPad() ? CGFloat(16) : CGFloat(12)
        style.minimumLineHeight  = prevailingLineHeight

        return style
    }()

    private lazy var noticonFont: UIFont = {
        let prevailingFontSize = UIDevice.isPad() ? CGFloat(15) : CGFloat(14)
        return UIFont(name: "Noticons", size: prevailingFontSize)!
    }()

    private lazy var prevailingBoldFont: UIFont = {
        return WPStyleGuide.fontForTextStyle(.footnote, symbolicTraits: .traitBold)
    }()

    private lazy var prevailingItalicizedFont: UIFont = {
        return WPStyleGuide.fontForTextStyle(.footnote, symbolicTraits: .traitItalic)
    }()

    private lazy var prevailingFont: UIFont = {
        return WPStyleGuide.fontForTextStyle(.footnote)
    }()

    // MARK: FormattableContentStyles

    var attributes: [NSAttributedString.Key: Any] {
        return [
            .paragraphStyle: paragraphStyle,
            .font: prevailingFont,
            .foregroundColor: UIColor.black
        ]
    }

    var quoteStyles: [NSAttributedString.Key: Any]? {
        return [
            .paragraphStyle: paragraphStyle,
            .font: prevailingItalicizedFont,
            .foregroundColor: UIColor.black
        ]
    }

    var rangeStylesMap: [FormattableRangeKind: [NSAttributedString.Key: Any]]? {
        return [
            .blockquote: [ .font: prevailingItalicizedFont ],
            .comment: [ .font: prevailingItalicizedFont ],
            .follow: [:],
            .italic: [ .font: prevailingItalicizedFont ],
            .link: [:],
            .match: [:],
            .noticon: [ .font: noticonFont ],
            .post: [ .font: prevailingItalicizedFont ],
            .site: [:],
            .stats: [:],
            .user: [ .font: prevailingBoldFont ],
        ]
    }

    var linksColor: UIColor? = nil

    var key: String = "RemoteNotificationStyles"
}
