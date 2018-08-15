import Foundation

/// Characterizes the types of service extension events we're interested in tracking.
/// The raw value corresponds to the event name in Tracks.
///
/// - launched: the service extension was successfully entered & launched
/// - discarded: the service extension launched, but encountered an unsupported notification type
/// - failed: the service extension failed to retrieve the payload
/// - assembled: the service extension successfully prepared content
///
private enum ServiceExtensionEvents: String {
    case launched   = "wpios_notification_service_extension_launched"
    case discarded  = "wpios_notification_service_extension_discarded"
    case failed     = "wpios_notification_service_extension_failed"
    case assembled  = "wpios_notification_service_extension_assembled"
}

// MARK: - Supports tracking notification service extension events.

extension Tracks {
    /// Tracks the successful launch of the notification service extension.
    ///
    /// - Parameter wpcomAvailable: `true` if an OAuth token exists, `false` otherwise
    func trackExtensionLaunched(_ wpcomAvailable: Bool) {
        let properties = [
            "is_configured_dotcom": wpcomAvailable
        ]
        trackEvent(ServiceExtensionEvents.launched, properties: properties as [String: AnyObject]?)
    }

    /// Utility method to capture an event & submit it to Tracks.
    ///
    /// - Parameters:
    ///   - event: the event to track
    ///   - properties: any accompanying metadata
    private func trackEvent(_ event: ServiceExtensionEvents, properties: [String: AnyObject]? = nil) {
        track(event.rawValue, properties: properties)
    }
}
