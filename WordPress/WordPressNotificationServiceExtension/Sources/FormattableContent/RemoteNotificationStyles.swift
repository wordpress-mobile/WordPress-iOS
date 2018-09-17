import Foundation

import WordPressShared
import WordPressUI

// MARK: - FormattableContentStyles

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
        if #available(iOS 11.0, *) {
            return WPStyleGuide.fontForTextStyle(.footnote, symbolicTraits: .traitBold)
        } else {
            let prevailingFontSize = UIDevice.isPad() ? CGFloat(16) : CGFloat(12)
            return WPFontManager.systemBoldFont(ofSize: prevailingFontSize)
        }
    }()

    private lazy var prevailingItalicizedFont: UIFont = {
        if #available(iOS 11.0, *) {
            return WPStyleGuide.fontForTextStyle(.footnote, symbolicTraits: .traitItalic)
        } else {
            let prevailingFontSize = UIDevice.isPad() ? CGFloat(16) : CGFloat(12)
            return WPFontManager.systemItalicFont(ofSize: prevailingFontSize)
        }
    }()

    private lazy var prevailingFont: UIFont = {
        if #available(iOS 11.0, *) {
            return WPStyleGuide.fontForTextStyle(.footnote)
        } else {
            let prevailingFontSize = UIDevice.isPad() ? CGFloat(16) : CGFloat(12)
            return WPFontManager.systemRegularFont(ofSize: prevailingFontSize)
        }
    }()

    // MARK: FormattableContentStyles

    var attributes: [NSAttributedStringKey: Any] {
        return [
            .paragraphStyle: paragraphStyle,
            .font: prevailingFont,
            .foregroundColor: UIColor.black
        ]
    }

    var quoteStyles: [NSAttributedStringKey: Any]? {
        return [
            .paragraphStyle: paragraphStyle,
            .font: prevailingItalicizedFont,
            .foregroundColor: UIColor.black
        ]
    }

    var rangeStylesMap: [FormattableRangeKind: [NSAttributedStringKey: Any]]? {
        return [
            .blockquote: [ .font: prevailingItalicizedFont ],
            .comment: [ .font: prevailingItalicizedFont ],
            .follow: [:],
            .italic: [:],
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
