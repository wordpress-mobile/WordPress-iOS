// MARK: - WordPressAuthenticator-Y Notifications
//
extension NSNotification.Name {
    /// Posted whenever the Login Flow has been cancelled.
    ///
    static let wordpressLoginCancelled = Foundation.Notification.Name(rawValue: "WordPressLoginCancelled")

    /// Posted whenever a Jetpack Login was successfully performed.
    ///
    static let wordpressLoginFinishedJetpackLogin = Foundation.Notification.Name(rawValue: "WordPressLoginFinishedJetpackLogin")

    /// Posted whenever the Support Badge needs to be updated.
    ///
    static let wordpressSupportBadgeUpdated = NSNotification.Name(rawValue: "WordPressSupportBadgeUpdated")
}
