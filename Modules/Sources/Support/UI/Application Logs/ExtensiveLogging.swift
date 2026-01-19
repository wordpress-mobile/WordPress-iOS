import SwiftUI
import PulseUI

public enum ExtensiveLogging {
    private static let expiryDateKey = "extensive_logging_expiry_date"

    public static var enabled: Bool {
        get {
            guard let expiryDate = UserDefaults.standard.object(forKey: expiryDateKey) as? Date else {
                return false
            }
            return expiryDate > Date()
        }
        set {
            if newValue {
                UserDefaults.standard.set(false, forKey: "pulse-disable-support-prompts")
                let expiryDate = Date().addingTimeInterval(24 * 60 * 60)
                UserDefaults.standard.set(expiryDate, forKey: expiryDateKey)
            } else {
                UserDefaults.standard.removeObject(forKey: expiryDateKey)
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
