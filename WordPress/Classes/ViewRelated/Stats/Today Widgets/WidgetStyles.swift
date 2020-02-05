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

    static var separatorVibrancyEffect: UIVibrancyEffect = {
        if #available(iOS 13, *) {
            return .widgetEffect(forVibrancyStyle: .separator)
        } else {
            return .widgetSecondary()
        }
    }()

    static func configureSeparator(_ separator: UIView) {
        // Both colors are need for the vibrancy effect.
        separator.backgroundColor = separatorColor
        separator.tintColor = separatorColor
    }

}
