import SwiftUI
import PulseUI

public enum ExtensiveLogging {
    private static let enabledKey = "extensive_logging_enabled"

    public static var enabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: enabledKey)
        }
        set {
            if newValue {
                UserDefaults.standard.set(false, forKey: "pulse-disable-support-prompts")
                UserDefaults.standard.set(true, forKey: enabledKey)
            } else {
                UserDefaults.standard.removeObject(forKey: enabledKey)
            }
        }
    }
}

public struct PulseMainView: UIViewControllerRepresentable {
    public init() {}

    public func makeUIViewController(context: Context) -> PulseUI.MainViewController {
        PulseUI.MainViewController()
    }

    public func updateUIViewController(_ uiViewController: PulseUI.MainViewController, context: Context) {}
}
