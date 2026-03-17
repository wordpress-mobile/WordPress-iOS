import Foundation
import WordPressShared

public struct UserSettings {
    /// Stores all `UserSettings` keys.
    ///
    /// The additional level of indirection allows these keys to be retrieved from tests.
    ///
    /// **IMPORTANT NOTE:**
    ///
    /// Any change to these keys is a breaking change without some kind of migration.
    /// It's probably best never to change them.
    public enum Keys: String, CaseIterable {
        case crashLoggingOptOutKey = "crashlytics_opt_out"
        case forceCrashLoggingKey = "force-crash-logging"
        case defaultDotComUUIDKey = "AccountDefaultDotcomUUID"
    }

    @UserDefault(Keys.crashLoggingOptOutKey.rawValue, defaultValue: false)
    public static var userHasOptedOutOfCrashLogging: Bool

    @UserDefault(Keys.forceCrashLoggingKey.rawValue, defaultValue: false)
    public static var userHasForcedCrashLoggingEnabled: Bool

    @NullableUserDefault(Keys.defaultDotComUUIDKey.rawValue)
    public static var defaultDotComUUID: String?

    /// Reset all UserSettings back to their defaults
    static func reset() {
        UserSettings.Keys.allCases.forEach { UserPersistentStoreFactory.instance().removeObject(forKey: $0.rawValue) }
    }
}

/// Objective-C Wrapper for UserSettings
@objc(UserSettings)
// FIXME: public access-level required only for the unit tests, which means that this is unused in prod. Let's migrate those tests soon!
public class ObjcCUserSettings: NSObject {
    @objc
    public static var defaultDotComUUID: String? {
        get { UserSettings.defaultDotComUUID }
        set { UserSettings.defaultDotComUUID = newValue }
    }

    @objc
    public static func reset() {
        UserSettings.reset()
    }
}

/// A property wrapper for UserDefaults access
@propertyWrapper
public struct UserDefault<T> {
    let key: String
    let defaultValue: T

    init(_ key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }

    public var wrappedValue: T {
        get {
            return UserPersistentStoreFactory.instance().object(forKey: key) as? T ?? defaultValue
        }
        set {
            UserPersistentStoreFactory.instance().set(newValue, forKey: key)
        }
    }
}

/// A property wrapper for optional UserDefaults that return `nil` by default
@propertyWrapper
public struct NullableUserDefault<T> {
    let key: String

    init(_ key: String) {
        self.key = key
    }

    public var wrappedValue: T? {
        get {
            return UserPersistentStoreFactory.instance().object(forKey: key) as? T
        }
        set {
            if let newValue {
                UserPersistentStoreFactory.instance().set(newValue, forKey: key)
            } else {
                UserPersistentStoreFactory.instance().removeObject(forKey: key)
            }
        }
    }
}
