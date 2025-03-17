import Foundation

struct BuildSettingsLiveContainer: BuildSettingsContainer {
    static let shared = BuildSettingsLiveContainer()

    var pushNotificationAppID: String {
        infoPlistValue(forKey: "WPPushNotificationAppID")
    }

    var appGroupName: String {
        infoPlistValue(forKey: "WPAppGroupName")
    }

    var appKeychainAccessGroup: String {
        infoPlistValue(forKey: "WPAppKeychainAccessGroup")
    }
}

private func infoPlistValue<T>(forKey key: String) -> T where T: LosslessStringConvertible {
    guard let object = Bundle.app.object(forInfoDictionaryKey: key) else {
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
