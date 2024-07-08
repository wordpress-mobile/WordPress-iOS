/// A `WordPressLoggingDelegate` implementation that logs to the Xcode console via `print`.
/// Useful for development or debugging. Not recommended in release builds.
public class ConsoleLogger: NSObject, WordPressLoggingDelegate {

    public func logError(_ str: String) {
        NSLog("❌ – Error: \(str)")
    }

    public func logWarning(_ str: String) {
        NSLog("⚠️ – Warning: \(str)")
    }

    public func logInfo(_ str: String) {
        NSLog("ℹ️ – Info: \(str)")
    }

    public func logDebug(_ str: String) {
        NSLog("🔎 – Debug: \(str)")
    }

    public func logVerbose(_ str: String) {
        NSLog("📃 – Verbose: \(str)")
    }
}
