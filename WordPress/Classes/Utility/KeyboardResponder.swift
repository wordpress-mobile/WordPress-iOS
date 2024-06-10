import Foundation
import SwiftUI
import Combine

final class KeyboardResponder: ObservableObject {
    @Published var notification: KeyboardNotification?

    /// Indicates whether the keyboard is currently animating based on the notification name.
    var isAnimating: Bool {
        guard let name = notification?.name else {
            return false
        }
        let names: Set<Foundation.Notification.Name> = [
            UIResponder.keyboardWillShowNotification,
            UIResponder.keyboardWillChangeFrameNotification,
            UIResponder.keyboardWillHideNotification
        ]
        return names.contains(name)
    }

    /// Provides a SwiftUI animation based on the keyboard's animation curve and duration.
    var animation: Animation? {
        guard let curve = notification?.animationCurve, let duration = notification?.animationDuration else {
            return nil
        }
        let timing = UICubicTimingParameters(animationCurve: curve)
        if let springParams = timing.springTimingParameters,
           let mass = springParams.mass, let stiffness = springParams.stiffness, let damping = springParams.damping,
           duration > 0 {
            return Animation.interpolatingSpring(mass: mass, stiffness: stiffness, damping: damping, initialVelocity: 0)
        }
        return nil
    }

    /// The duration of the keyboard animation.
    var animationDuration: TimeInterval {
        return notification?.animationDuration ?? 0
    }
}

struct KeyboardNotification: Equatable {
    let name: Foundation.Notification.Name
    let animationCurve: UIView.AnimationCurve?
    let animationDuration: TimeInterval?
    let fromFrame: CGRect?
    let toFrame: CGRect?

    init(_ note: Foundation.Notification) {
        let duration = note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
        let curve: UIView.AnimationCurve?  = {
            guard let rawValue = note.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int else {
                return nil
            }
            return .init(rawValue: rawValue)
        }()
        self.animationDuration = duration
        self.animationCurve = curve
        self.fromFrame = note.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? CGRect
        self.toFrame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        self.name = note.name
    }
}

extension View {
    var keyboardPublisher: AnyPublisher<KeyboardNotification, Never> {
        let center = NotificationCenter.default
        return Publishers.MergeMany([
            center.publisher(for: UIResponder.keyboardWillShowNotification),
            center.publisher(for: UIResponder.keyboardWillHideNotification),
            center.publisher(for: UIResponder.keyboardWillChangeFrameNotification),
            center.publisher(for: UIResponder.keyboardDidChangeFrameNotification),
            center.publisher(for: UIResponder.keyboardDidShowNotification),
            center.publisher(for: UIResponder.keyboardDidHideNotification)
        ])
        .map { note -> KeyboardNotification in
            KeyboardNotification(note)
        }
        .eraseToAnyPublisher()
    }
}

private extension UISpringTimingParameters {
    var mass: Double? {
        value(forKey: "mass") as? Double
    }
    var stiffness: Double? {
        value(forKey: "stiffness") as? Double
    }
    var damping: Double? {
        value(forKey: "damping") as? Double
    }
}
