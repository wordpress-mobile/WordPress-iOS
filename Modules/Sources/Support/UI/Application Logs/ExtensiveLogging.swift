import Foundation

public enum ExtensiveLogging {
    private static let enabledKey = "extensive_logging_enabled"

    public static var enabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: enabledKey)
        }
        set {
            if newValue {
                UserDefaults.standard.set(true, forKey: "pulse-disable-settings-prompts")
                UserDefaults.standard.set(true, forKey: "pulse-disable-support-prompts")
                UserDefaults.standard.set(true, forKey: "pulse-disable-report-issue-prompts")
                UserDefaults.standard.set(true, forKey: enabledKey)
            } else {
                UserDefaults.standard.removeObject(forKey: enabledKey)
            }
        }
    }
}
