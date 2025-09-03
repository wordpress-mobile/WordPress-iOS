import Foundation

/// This struct encapsulates the *remote* Jetpack monitor settings available for a Blog entity
///
public struct RemoteBlogJetpackMonitorSettings {

    /// Indicates whether the Jetpack site's monitor notifications should be sent by email
    ///
    public let monitorEmailNotifications: Bool

    /// Indicates whether the Jetpack site's monitor notifications should be sent by push notifications
    ///
    public let monitorPushNotifications: Bool

    public init(monitorEmailNotifications: Bool,
                monitorPushNotifications: Bool) {
        self.monitorEmailNotifications = monitorEmailNotifications
        self.monitorPushNotifications = monitorPushNotifications
    }

}
