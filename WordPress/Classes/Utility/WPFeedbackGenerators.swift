import UIKit

@objc
public enum WPNotificationFeedbackType : Int {
    case Success
    case Warning
    case Error

    @available(iOS 10, *)
    var systemFeedbackType: UINotificationFeedbackType {
        switch self {
        case .Success: return .Success
        case .Warning: return .Warning
        case .Error: return .Error
        }
    }
}

/// iOS's taptic feedback classes are only available for iOS 10+.
/// This is a small wrapper around UINotificationFeedbackGenerator, which simply
/// results in a no-op on iOS 9 – avoiding the need for conditional code
/// throughout the app.
/// - seealso: UINotificationFeedbackGenerator
@objc
class WPNotificationFeedbackGenerator: NSObject {
    class func notificationOccurred(notificationType: WPNotificationFeedbackType) {
        guard #available(iOS 10, *) else {
            return
        }

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(notificationType.systemFeedbackType)
    }
}

@objc
public enum WPImpactFeedbackStyle : Int {
    case Light
    case Medium
    case Heavy

    @available(iOS 10, *)
    var systemFeedbackStyle: UIImpactFeedbackStyle {
        switch self {
        case .Light: return .Light
        case .Medium: return .Medium
        case .Heavy: return .Heavy
        }
    }
}

/// iOS's taptic feedback classes are only available for iOS 10+.
/// This is a small wrapper around UIImpactFeedbackGenerator, which simply
/// results in a no-op on iOS 9 – avoiding the need for conditional code
/// throughout the app.
/// - seealso: UIImpactFeedbackGenerator
@objc
class WPImpactFeedbackGenerator: NSObject {
    let style: WPImpactFeedbackStyle

    init(style: WPImpactFeedbackStyle) {
        self.style = style
        super.init()
    }

    /// call when your UI element impacts something else
    func impactOccurred() {
        guard #available(iOS 10, *) else {
            return
        }

        let generator = UIImpactFeedbackGenerator(style: style.systemFeedbackStyle)
        generator.impactOccurred()
    }
}
