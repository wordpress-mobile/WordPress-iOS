import UIKit

@objc
public enum WPNotificationFeedbackType : Int {
    case success
    case warning
    case error

    @available(iOS 10, *)
    var systemFeedbackType: UINotificationFeedbackType {
        switch self {
        case .success: return .success
        case .warning: return .warning
        case .error: return .error
        }
    }
}

// This allows us to more easily inject a generator into our custom wrapper
// for testing, whilst also supporting iOS 9.
protocol WPNotificationFeedbackGeneratorConformance {
    @available(iOS 10, *)
    func notificationOccurred(_ notificationType: UINotificationFeedbackType)
}

@available(iOS 10, *)
extension UINotificationFeedbackGenerator: WPNotificationFeedbackGeneratorConformance {}

/// iOS's taptic feedback classes are only available for iOS 10+.
/// This is a small wrapper around UINotificationFeedbackGenerator, which simply
/// results in a no-op on iOS 9 – avoiding the need for conditional code
/// throughout the app.
/// - seealso: UINotificationFeedbackGenerator
@objc
class WPNotificationFeedbackGenerator: NSObject {
    static var generator: WPNotificationFeedbackGeneratorConformance?

    class func notificationOccurred(_ notificationType: WPNotificationFeedbackType) {
        guard #available(iOS 10, *) else { return }

        if generator == nil {
            generator = UINotificationFeedbackGenerator()
        }

        generator?.notificationOccurred(notificationType.systemFeedbackType)
    }
}

@objc
public enum WPImpactFeedbackStyle : Int {
    case light
    case medium
    case heavy

    @available(iOS 10, *)
    var systemFeedbackStyle: UIImpactFeedbackStyle {
        switch self {
        case .light: return .light
        case .medium: return .medium
        case .heavy: return .heavy
        }
    }
}

// This allows us to more easily inject a generator into our custom wrapper
// for testing, whilst also supporting iOS 9.
protocol WPImpactFeedbackGeneratorConformance {
    func impactOccurred()
}

@available(iOS 10, *)
extension UIImpactFeedbackGenerator: WPImpactFeedbackGeneratorConformance {}


/// iOS's taptic feedback classes are only available for iOS 10+.
/// This is a small wrapper around UIImpactFeedbackGenerator, which simply
/// results in a no-op on iOS 9 – avoiding the need for conditional code
/// throughout the app.
/// - seealso: UIImpactFeedbackGenerator
@objc
class WPImpactFeedbackGenerator: NSObject {
    internal var generator: WPImpactFeedbackGeneratorConformance?

    init(style: WPImpactFeedbackStyle) {
        if #available(iOS 10, *) {
            generator = UIImpactFeedbackGenerator(style: style.systemFeedbackStyle)
        }

        super.init()
    }

    func impactOccurred() {
        generator?.impactOccurred()
    }
}
