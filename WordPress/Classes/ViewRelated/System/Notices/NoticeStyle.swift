import UIKit
import WordPressShared
import DesignSystem

public enum NoticeAnimationStyle {
    case moveIn
    case fade
}

/// A gesture which can be used to dismiss the notice.
/// See `NoticeView.configurGestureRecognizer()` for more details.
public enum NoticeDismissGesture {
    case tap
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

    /// The space between the border of the Notice and the contents (title, label, and buttons).
    var directionalLayoutMargins: NSDirectionalEdgeInsets { get }

    // Misc
    var isDismissable: Bool { get }
    var animationStyle: NoticeAnimationStyle { get }
    var dismissGesture: NoticeDismissGesture? { get }

    // Show an arrow (>) after the action button.
    var showNextArrow: Bool { get }

    /// An icon shown before the title. When `nil`, the icon is based on the notice's feedback type.
    var icon: UIImage? { get }
}

extension NoticeStyle {
    public var titleColor: UIColor {
        .label
    }

    public var messageColor: UIColor {
        .secondaryLabel
    }

    // Return new UIFont instance everytime in order to be responsive to accessibility font size changes
    public var messageLabelFont: UIFont { WPStyleGuide.fontForTextStyle(.footnote) }

    public var icon: UIImage? { nil }
}

public struct NormalNoticeStyle: NoticeStyle {
    public let attributedMessage: NSAttributedString? = nil

    // Return new UIFont instance everytime in order to be responsive to accessibility font size changes
    public var titleLabelFont: UIFont { WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold) }
    public var actionButtonFont: UIFont? { WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold) }
    public let cancelButtonFont: UIFont? = nil

    public let directionalLayoutMargins = NSDirectionalEdgeInsets(
        top: 12.0,
        leading: 20.0,
        bottom: 12.0,
        trailing: 20.0
    )

    public let isDismissable = true
    public var showNextArrow = false

    public let animationStyle = NoticeAnimationStyle.moveIn

    public let dismissGesture: NoticeDismissGesture? = nil
}

public struct InAppUpdateNoticeStyle: NoticeStyle {
    public let attributedMessage: NSAttributedString?

    init(attributedMessage: NSAttributedString? = nil) {
        self.attributedMessage = attributedMessage
    }

    // Return new UIFont instance everytime in order to be responsive to accessibility font size changes
    public var titleLabelFont: UIFont { WPStyleGuide.fontForTextStyle(.subheadline, fontWeight: .semibold) }
    public var actionButtonFont: UIFont? { WPStyleGuide.fontForTextStyle(.headline) }
    public var cancelButtonFont: UIFont? { WPStyleGuide.fontForTextStyle(.body) }

    public let directionalLayoutMargins = NSDirectionalEdgeInsets(
        top: 16.0,
        leading: 20.0,
        bottom: 12.0,
        trailing: 20.0
    )

    public var isDismissable = false
    public let showNextArrow = false

    public var icon: UIImage? { UIImage(systemName: "arrow.down.circle.dotted") }

    public let animationStyle = NoticeAnimationStyle.moveIn

    public let dismissGesture: NoticeDismissGesture? = nil
}
