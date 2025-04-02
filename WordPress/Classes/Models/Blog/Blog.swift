import BuildSettingsKit

extension Blog {

    @objc
    public func supportsRestApi() -> Bool {
        // We don't want to check for `restApi` as it can be `nil` when the token is missing from
        // the keychain
        account != nil
    }
}
