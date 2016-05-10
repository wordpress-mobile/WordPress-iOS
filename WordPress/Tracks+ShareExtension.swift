import Foundation


/// This extension implements helper tracking methods, meant for Share Extension Usage.
///
extension Tracks
{
    // MARK: - Public Methods
    public func trackExtensionLaunched(wpcomAvailable: Bool) {
        let properties = ["is_configured_dotcom" : wpcomAvailable]
        trackExtensionEvent(.Launched, properties: properties)
    }

    public func trackExtensionPosted(status: String) {
        let properties = ["post_status" : status]
        trackExtensionEvent(.Posted, properties: properties)
    }

    public func trackExtensionCancelled() {
        trackExtensionEvent(.Canceled)
    }


    // MARK: - Private Helpers
    private func trackExtensionEvent(event: ExtensionEvents, properties: [String: AnyObject]? = nil) {
        track(event.rawValue, properties: properties)
    }


    // MARK: - Private Enums
    private enum ExtensionEvents : String {
        case Launched   = "wpios_share_extension_launched"
        case Posted     = "wpios_share_extension_posted"
        case Canceled   = "wpios_share_extension_canceled"
    }
}
