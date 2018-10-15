import Foundation

/// Characterizes the types of content extension events we're interested in tracking.
/// The raw value corresponds to the event name in Tracks.
///
/// - launched: the content extension was successfully entered & launched
///
private enum ContentExtensionEvents: String {
    case launched           = "wpios_notification_content_extension_launched"
    case failedToMarkAsRead = "wpios_notification_content_extension_failed_mark_as_read"
}

// MARK: - Supports tracking notification content extension events.

extension Tracks {
    /// Tracks the successful launch of the notification content extension.
    ///
    /// - Parameter wpcomAvailable: `true` if an OAuth token exists, `false` otherwise
    func trackExtensionLaunched(_ wpcomAvailable: Bool) {
        let properties = [
            "is_configured_dotcom": wpcomAvailable
        ]
        trackEvent(ContentExtensionEvents.launched, properties: properties as [String: AnyObject]?)
    }

    /// Tracks the failure to mark a notification as read via the REST API.
    ///
    /// - Parameters:
    ///   - notificationIdentifier: the value of the `note_id` from the APNS payload
    ///   - errorDescription: description of the error encountered, ideally localized
    func trackFailedToMarkNotificationAsRead(notificationIdentifier: String, errorDescription: String) {
        let properties = [
            "note_id": notificationIdentifier,
            "error": errorDescription
        ]
        trackEvent(ContentExtensionEvents.failedToMarkAsRead, properties: properties as [String: AnyObject]?)
    }

    /// Utility method to capture an event & submit it to Tracks.
    ///
    /// - Parameters:
    ///   - event: the event to track
    ///   - properties: any accompanying metadata
    private func trackEvent(_ event: ContentExtensionEvents, properties: [String: AnyObject]? = nil) {
        track(event.rawValue, properties: properties)
    }
}
