import BuildSettingsKit

public extension WPAccount {

    @objc class var authKeychainServiceName: String {
        BuildSettings.current.authKeychainServiceName
    }
}
