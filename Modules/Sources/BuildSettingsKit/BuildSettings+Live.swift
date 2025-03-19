import Foundation

extension BuildSettings {
    static let live = BuildSettings(bundle: .app)

    init(bundle: Bundle) {
        brand = AppBrand(rawValue: bundle.infoValue(forKey: "WPAppBrand"))!
        pushNotificationAppID = bundle.infoValue(forKey: "WPPushNotificationAppID")
        appGroupName = bundle.infoValue(forKey: "WPAppGroupName")
        appKeychainAccessGroup = bundle.infoValue(forKey: "WPAppKeychainAccessGroup")
        eventNamePrefix = bundle.infoValue(forKey: "WPEventNamePrefix")
        explatPlatform = bundle.infoValue(forKey: "WPExplatPlatform")
    }
}

private extension Bundle {
    func infoValue<T>(forKey key: String) -> T where T: LosslessStringConvertible {
        guard let object = object(forInfoDictionaryKey: key) else {
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
}

private extension Bundle {
    /// Returns the `Bundle` for the host `.app`.
    ///
    /// - If this is called from code already located in the main app's bundle or from a Pod/Framework,
    ///   this will return the same as `Bundle.main`, aka the bundle of the app itself.
    /// - If this is called from an App Extension (Widget, ShareExtension, etc), this will return the bundle of the
    ///   main app hosting said App Extension (while `Bundle.main` would return the App Extension itself)
    static let app: Bundle = {
        var url = Bundle.main.bundleURL
        while url.pathExtension != "app" && url.lastPathComponent != "/" {
            url.deleteLastPathComponent()
        }
        guard let appBundle = Bundle(url: url) else { fatalError("Unable to find the parent app bundle") }
        return appBundle
    }()
}
