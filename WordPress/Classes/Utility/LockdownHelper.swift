import Foundation

/// Reports whether iOS Lockdown Mode is enabled.
///
/// Lockdown Mode can only be toggled with a device restart, so its state is constant
/// for the lifetime of the process. The flag is therefore read once — lazily, on first
/// access — from the system-maintained `LDMGlobalEnabled` user default; `static let`
/// makes that read thread-safe and the result immutable.
enum LockdownHelper {
    /// The system-maintained global user default, set while Lockdown Mode is enabled.
    private static let lockdownModeDefaultsKey = "LDMGlobalEnabled"

    static let isLockdownModeEnabled = UserDefaults.standard.bool(forKey: lockdownModeDefaultsKey)
}
