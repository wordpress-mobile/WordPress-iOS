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

// MARK: - Support for tracking notification service extension support.

extension Tracks {}
