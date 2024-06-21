// MARK: - WordPressAuthenticator-Y Notifications
//
extension NSNotification.Name {
    /// Posted whenever the Login Flow has been cancelled.
    ///
    public static let wordpressLoginCancelled = Foundation.Notification.Name(rawValue: "WordPressLoginCancelled")

    /// Posted whenever a Jetpack Login was successfully performed.
    ///
    public static let wordpressLoginFinishedJetpackLogin = Foundation.Notification.Name(rawValue: "WordPressLoginFinishedJetpackLogin")

    /// Posted whenever a Support notification is received.
    ///
    public static let wordpressSupportNotificationReceived = NSNotification.Name(rawValue: "WordPressSupportNotificationReceived")

    /// Posted whenever a Support notification has been viewed.
    ///
    public static let wordpressSupportNotificationCleared = NSNotification.Name(rawValue: "WordPressSupportNotificationCleared")
}
