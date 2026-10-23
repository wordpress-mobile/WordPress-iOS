public protocol KeychainAccessible {
    func getPassword(for username: String, serviceName: String) throws -> String
    func setPassword(for username: String, to newValue: String?, serviceName: String) throws

    /// Access to items that iCloud Keychain syncs to the user's other devices. Use it for
    /// credentials that should follow the user to a new device, such as application passwords.
    ///
    /// `AppKeychain` returns a `SynchronizableAppKeychain`. The default implementation returns
    /// `self`, which keeps test doubles in use.
    var synchronizable: any KeychainAccessible { get }
}

public extension KeychainAccessible {
    var synchronizable: any KeychainAccessible {
        self
    }
}
