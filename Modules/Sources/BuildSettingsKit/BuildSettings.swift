import Foundation

/// Provides convenient access for values defined in Info.plist files for
/// apps and app extensions.
///
/// - warning: Most of these values exist only in Info.plist files for apps as
/// app extensions only need a tiny subset of these settings.
public enum BuildSettings {
    public static var pushNotificationAppID: String {
        infoPlistValue(forKey: "WPPushNotificationAppID")
    }

    public static var appGroupName: String {
        infoPlistValue(forKey: "WPAppGroupName")
    }

    public static var appKeychainAccessGroup: String {
        infoPlistValue(forKey: "WPAppKeychainAccessGroup")
    }
}

private func infoPlistValue<T>(forKey key: String) -> T where T: LosslessStringConvertible {
    guard let object = Bundle.main.object(forInfoDictionaryKey: key) else {
        fatalError("missing value for key: \(key)")
    }
    switch object {
    case let value as T:
        return value
    case let string as String:
        guard let value = T(string) else { fallthrough }
        return value
    default:
        fatalError("unexpected value: \(object) for key: \(key)")
    }
}
