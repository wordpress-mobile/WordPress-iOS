public enum NoticeAnimationStyle {
    case moveIn
    case fade
}

/// A gesture which can be used to dismiss the notice.
/// See `NoticeView.configurGestureRecognizer()` for more details.
public enum NoticeDismissGesture {
    case tap
}

// iOS 12 color compatibility
private enum Compatibility {
    static let systemGray5 = UIColor(displayP3Red: 229/255, green: 229/255, blue: 234/255, alpha: 1)
    static let secondaryLabel = UIColor(displayP3Red: 60/255, green: 60/255, blue: 67/255, alpha: 0.6)
}

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
    var actionButtonTitleColor: UIColor { get }

    /// The space between the border of the Notice and the contents (title, label, and buttons).
    var layoutMargins: UIEdgeInsets { get }

    // Misc
    var isDismissable: Bool { get }
    var animationStyle: NoticeAnimationStyle { get }
    var dismissGesture: NoticeDismissGesture? { get }
}

extension NoticeStyle {
    public var backgroundColor: UIColor {
        .invertedSystem5
    }

    public var titleColor: UIColor {
        .invertedLabel
    }

    public var messageColor: UIColor {
        .invertedSecondaryLabel
    }

    public var actionButtonTitleColor: UIColor {
        .invertedLabel
    }
}

public struct NormalNoticeStyle: NoticeStyle {
    public let attributedMessage: NSAttributedString? = nil

    // Return new UIFont instance everytime in order to be responsive to accessibility font size changes
    public var titleLabelFont: UIFont { return UIFont.boldSystemFont(ofSize: 14.0) }
    public var messageLabelFont: UIFont { return UIFont.systemFont(ofSize: 14.0) }
    public var actionButtonFont: UIFont? { return UIFont.systemFont(ofSize: 14.0, weight: .medium) }
    public let cancelButtonFont: UIFont? = nil

    public let layoutMargins = UIEdgeInsets(top: 10.0, left: 16.0, bottom: 10.0, right: 16.0)

    public let isDismissable = true

    public let animationStyle = NoticeAnimationStyle.moveIn

    public let dismissGesture: NoticeDismissGesture? = nil
}

public struct QuickStartNoticeStyle: NoticeStyle {
    public let attributedMessage: NSAttributedString?

    // Return new UIFont instance everytime in order to be responsive to accessibility font size changes
    public var titleLabelFont: UIFont { return WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold) }
    public var messageLabelFont: UIFont { return WPStyleGuide.fontForTextStyle(.subheadline) }
    public var actionButtonFont: UIFont? { return WPStyleGuide.fontForTextStyle(.headline) }
    public var cancelButtonFont: UIFont? { return WPStyleGuide.fontForTextStyle(.body) }

    public let layoutMargins = UIEdgeInsets(top: 13.0, left: 16.0, bottom: 13.0, right: 16.0)

    public let isDismissable = false

    public let animationStyle = NoticeAnimationStyle.moveIn

    public let dismissGesture: NoticeDismissGesture? = nil
}

public struct ToolTipNoticeStyle: NoticeStyle {
    public let attributedMessage: NSAttributedString?

    init(attributedMessage: NSAttributedString? = nil) {
        self.attributedMessage = attributedMessage
    }

    // Return new UIFont instance everytime in order to be responsive to accessibility font size changes
    public var titleLabelFont: UIFont { return WPStyleGuide.fontForTextStyle(.body) }
    public var messageLabelFont: UIFont { return WPStyleGuide.fontForTextStyle(.subheadline) }
    public var actionButtonFont: UIFont? { return WPStyleGuide.fontForTextStyle(.headline) }
    public var cancelButtonFont: UIFont? { return WPStyleGuide.fontForTextStyle(.body) }

    public let layoutMargins = UIEdgeInsets(top: 13.0, left: 16.0, bottom: 13.0, right: 16.0)

    public let isDismissable = false

    public let animationStyle = NoticeAnimationStyle.fade

    public let dismissGesture: NoticeDismissGesture? = NoticeDismissGesture.tap
}
