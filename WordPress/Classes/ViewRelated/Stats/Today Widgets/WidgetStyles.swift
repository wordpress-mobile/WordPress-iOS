import Foundation
import NotificationCenter

class WidgetStyles: NSObject {

    static let primaryTextColor: UIColor = .text
    static let secondaryTextColor: UIColor = .textSubtle

    private static var separatorColor: UIColor = {
        if #available(iOS 13, *) {
            return .separator
        } else {
            return .divider
        }
    }()

    static func configureSeparator(_ separator: UIView) {
        // Both colors are need for the vibrancy effect.
        separator.backgroundColor = separatorColor
        separator.tintColor = separatorColor
    }

    static func configureSeparatorVisualEffectView(_ visualEffectView: UIVisualEffectView) {
        if #available(iOS 13, *) {
            visualEffectView.effect = UIVibrancyEffect.widgetEffect(forVibrancyStyle: .separator)
        } else {
            visualEffectView.effect = UIVibrancyEffect.widgetSecondary()
        }
    }

}
