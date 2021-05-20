import Foundation

struct UserSettings {
    /// Stores all `UserSettings` keys.
    ///
    /// The additional level of indirection allows these keys to be retrieved from tests.
    ///
    /// **IMPORTANT NOTE:**
    ///
    /// Any change to these keys is a breaking change without some kind of migration.
    /// It's probably best never to change them.
    enum Keys: String, CaseIterable {
        case crashLoggingOptOutKey = "crashlytics_opt_out"
        case forceCrashLoggingKey = "force-crash-logging"
        case defaultDotComUUIDKey = "AccountDefaultDotcomUUID"
    }

    @UserDefault(Keys.crashLoggingOptOutKey.rawValue, defaultValue: false)
    static var userHasOptedOutOfCrashLogging: Bool

    @UserDefault(Keys.forceCrashLoggingKey.rawValue, defaultValue: false)
    static var userHasForcedCrashLoggingEnabled: Bool

    @NullableUserDefault(Keys.defaultDotComUUIDKey.rawValue)
    static var defaultDotComUUID: String?

    /// Reset all UserSettings back to their defaults
    static func reset() {
        UserSettings.Keys.allCases.forEach { UserDefaults.standard.removeObject(forKey: $0.rawValue) }
    }
}

/// Objective-C Wrapper for UserSettings
@objc(UserSettings)
class ObjcCUserSettings: NSObject {
    @objc
    static var defaultDotComUUID: String? {
        get { UserSettings.defaultDotComUUID }
        set { UserSettings.defaultDotComUUID = newValue }
    }

    @objc
    static func reset() {
        UserSettings.reset()
    }
}

/// A property wrapper for UserDefaults access
@propertyWrapper
struct UserDefault<T> {
    let key: String
    let defaultValue: T

    init(_ key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }

    var wrappedValue: T {
        get {
            return UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}

/// A property wrapper for optional UserDefaults that return `nil` by default
@propertyWrapper
struct NullableUserDefault<T> {
    let key: String

    init(_ key: String) {
        self.key = key
    }

    var wrappedValue: T? {
        get {
            return UserDefaults.standard.object(forKey: key) as? T
        }
        set {
            if let newValue = newValue {
                UserDefaults.standard.set(newValue, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }
}
