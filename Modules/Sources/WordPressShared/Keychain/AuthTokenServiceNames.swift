/// Keychain service names for the WP.com OAuth tokens. These form a
/// cross-app contract (see `SharedKeychain`): the WordPress app publishes
/// its token under `wordPress` for the Jetpack app to import, the group
/// sweep preserves that item, and each app's copy skips the other's token.
/// Old app versions hardcode both values, so they must never change.
public enum AuthTokenServiceNames {
    public static let wordPress = "public-api.wordpress.com"
    public static let jetpack = "jetpack.public-api.wordpress.com"
}
