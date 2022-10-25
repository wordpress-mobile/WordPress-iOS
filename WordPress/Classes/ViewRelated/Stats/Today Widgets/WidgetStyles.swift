import Foundation
import NotificationCenter

class WidgetStyles: NSObject {

    static let primaryTextColor: UIColor = .text
    static let secondaryTextColor: UIColor = .textSubtle
    static let headlineFont = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .headline).pointSize)
    static let footnoteNote = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .footnote).pointSize)

    static var separatorColor: UIColor = {
        if #available(iOS 13, *) {
            return .separator
        } else {
            return .divider
        }
    }()

    // Note: Before supporting only iOS 14+, this used to be:
    //
    // - .widgetEffect(forVibrancyStyle: .separator) in iOS 13+
    // - .widgetSecondary() in previous versions
    //
    // Hopefully this information is useful if the current implementation is not visually satisfying.
    static var separatorVibrancyEffect = UIVibrancyEffect(
        blurEffect: UIBlurEffect(style: .regular),
        style: .separator
    )

    static func configureSeparator(_ separator: UIView) {
        // Both colors are need for the vibrancy effect.
        separator.backgroundColor = separatorColor
        separator.tintColor = separatorColor
    }

}
