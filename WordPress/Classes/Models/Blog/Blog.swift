import BuildSettingsKit

extension Blog {

    @objc
    @available(*, unavailable)
    public func supportsStockPhotos() -> Bool {
        supportsStockPhotos(buildSettings: .current)
    }

    func supportsStockPhotos(buildSettings: BuildSettings = .current) -> Bool {
        return supportsRestApi() && buildSettings.brand == .jetpack
    }

    @objc
    @available(*, unavailable)
    public func supportsTenor() -> Bool {
        supportsTenor(buildSettings: .current)
    }

    func supportsTenor(buildSettings: BuildSettings = .current) -> Bool {
        return buildSettings.brand == .jetpack
    }

    @objc
    public func supportsRestApi() -> Bool {
        // We don't want to check for `restApi` as it can be `nil` when the token is missing from
        // the keychain
        account != nil
    }
}
