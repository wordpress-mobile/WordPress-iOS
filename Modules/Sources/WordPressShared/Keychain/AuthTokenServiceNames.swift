/// Keychain service names for the WP.com OAuth tokens. These form a
/// cross-app contract (see `SharedKeychain`): at migration-export time the
/// WordPress app publishes its token to the shared group under `wordPress`,
/// and the Jetpack app reads it from there and re-stores it under `jetpack`
/// in its own private group. Old app versions hardcode both values, so they
/// must never change.
public enum AuthTokenServiceNames {
    public static let wordPress = "public-api.wordpress.com"
    public static let jetpack = "jetpack.public-api.wordpress.com"
}
