import Foundation

class UserSettings {

    @objc
    @UserDefault("crashlytics_opt_out", defaultValue: false)
    static var userHasOptedOutOfCrashLogging: Bool

    @objc
    @UserDefault("force-crash-logging", defaultValue: false)
    static var userHasForcedCrashLoggingEnabled: Bool
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
