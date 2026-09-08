import Foundation
import WebKit
import os

/// Reports iOS Lockdown Mode state at two scopes.
///
/// The media-import failure this guards originates in the shared `PhotosFileProvider`
/// system extension, which stays memory-restricted whenever Lockdown Mode is enabled
/// *device-wide* — even for an app the user has excluded from Lockdown Mode (verified on
/// device: an excluded app's import still fails). So the device-wide flag is what
/// correlates with the failure and drives the error copy; the per-app value is recorded
/// only as secondary telemetry.
enum LockdownHelper {
    /// The system-maintained global user default, set while Lockdown Mode is enabled.
    private static let lockdownModeDefaultsKey = "LDMGlobalEnabled"

    /// Whether Lockdown Mode is enabled device-wide. Governs shared system services like
    /// `PhotosFileProvider`, so it's the signal that correlates with the media-import
    /// failure. Device-wide Lockdown Mode only toggles on a device restart, so it's read
    /// once — lazily, on first access — and constant for the process; `static let` makes
    /// that read thread-safe and the result immutable.
    static let isDeviceLockdownModeEnabled = UserDefaults.standard.bool(forKey: lockdownModeDefaultsKey)

    /// Cached per-app Lockdown Mode state, populated by `primeAppLockdownState()`.
    private static let appLockdownState = OSAllocatedUnfairLock(initialState: false)

    /// Reads and caches whether *this app* is running under Lockdown Mode.
    ///
    /// The value comes from WebKit's per-app-effective `isLockdownModeEnabled`, which is
    /// `@MainActor`; the sole reader (`ItemProviderMediaExporter`) runs on a background
    /// callback queue, and the per-app value is applied at process launch and constant
    /// thereafter — so it's read once here on the main actor and cached for later reads.
    ///
    /// Call once, early, on the main actor (from `didFinishLaunchingWithOptions`).
    @MainActor static func primeAppLockdownState() {
        let isEnabled = WKWebViewConfiguration().defaultWebpagePreferences.isLockdownModeEnabled
        appLockdownState.withLock { $0 = isEnabled }
    }

    /// Whether *this app* is itself running under Lockdown Mode (`false` if the user has
    /// excluded it). Valid only after `primeAppLockdownState()`; defaults to `false`.
    static var isAppLockdownModeEnabled: Bool {
        appLockdownState.withLock { $0 }
    }
}
