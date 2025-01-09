import UIKit
import SwiftUI

public extension EdgeInsets {
    static let zero = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
}

private struct PresentingViewControllerKey: EnvironmentKey {
    static let defaultValue = WeakEnvironmentValueWrapper<UIViewController>()
}

extension EnvironmentValues {
    public var presentingViewController: UIViewController? {
        get {
            self[PresentingViewControllerKey.self].value ?? UIViewController.topViewController
        }
        set {
            self[PresentingViewControllerKey.self].value = newValue
        }
    }
}

private final class WeakEnvironmentValueWrapper<T: AnyObject> {
    weak var value: T?
}
