public protocol NoticeStyle {
    // Text
    var attributedMessage: NSAttributedString? { get }

    // Fonts
    var titleLabelFont: UIFont { get }
    var messageLabelFont: UIFont { get }
    var actionButtonFont: UIFont? { get }
    var cancelButtonFont: UIFont? { get }

    // Colors
    var titleColor: UIColor { get }
    var messageColor: UIColor { get }
    var backgroundColor: UIColor { get }

    /// The space between the border of the Notice and the contents (title, label, and buttons).
    var layoutMargins: UIEdgeInsets { get }

    // Misc
    var isDismissable: Bool { get }
}


public struct NormalNoticeStyle: NoticeStyle {
    public let attributedMessage: NSAttributedString? = nil

    public let titleLabelFont = UIFont.boldSystemFont(ofSize: 14.0)
    public let messageLabelFont = UIFont.systemFont(ofSize: 14.0)
    public let actionButtonFont: UIFont? = UIFont.systemFont(ofSize: 14.0)
    public let cancelButtonFont: UIFont? = nil

    public let titleColor: UIColor = .white
    public let messageColor: UIColor = .white
    public let backgroundColor: UIColor = WPStyleGuide.grey700()

    public let layoutMargins = UIEdgeInsets(top: 12.0, left: 16.0, bottom: 12.0, right: 16.0)

    public let isDismissable = true
}

public struct QuickStartNoticeStyle: NoticeStyle {
    public let attributedMessage: NSAttributedString?

    public let titleLabelFont = WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold)
    public let messageLabelFont = WPStyleGuide.fontForTextStyle(.subheadline)
    public let actionButtonFont: UIFont? = WPStyleGuide.fontForTextStyle(.headline)
    public let cancelButtonFont: UIFont? = WPStyleGuide.fontForTextStyle(.body)

    public let titleColor: UIColor = .white
    public let messageColor: UIColor = WPStyleGuide.greyLighten20()
    public let backgroundColor: UIColor = WPStyleGuide.darkGrey().withAlphaComponent(0.88)

    public let layoutMargins = UIEdgeInsets(top: 13.0, left: 16.0, bottom: 13.0, right: 16.0)

    public let isDismissable = false
}
