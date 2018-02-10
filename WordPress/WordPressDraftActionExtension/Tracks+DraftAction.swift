import Foundation

/// This extension implements helper tracking methods, meant for Draft Action Extension usage.
///
extension Tracks {
    // MARK: - Public Methods
    public func trackExtensionLaunched(_ wpcomAvailable: Bool) {
        let properties = ["is_configured_dotcom": wpcomAvailable]
        trackExtensionEvent(.Launched, properties: properties as [String: AnyObject]?)
    }

    public func trackExtensionPosted(_ status: String) {
        let properties = ["post_status": status]
        trackExtensionEvent(.Posted, properties: properties as [String: AnyObject]?)
    }

    public func trackExtensionError(_ error: NSError) {
        let properties = ["error_code": String(error.code), "error_domain": error.domain, "error_description": error.description]
        trackExtensionEvent(.Error, properties: properties as [String: AnyObject]?)
    }

    public func trackExtensionCancelled() {
        trackExtensionEvent(.Canceled)
    }

    // MARK: - Private Helpers

    fileprivate func trackExtensionEvent(_ event: ExtensionEvents, properties: [String: AnyObject]? = nil) {
        track(event.rawValue, properties: properties)
    }

    // MARK: - Private Enums

    fileprivate enum ExtensionEvents: String {
        case Launched   = "wpios_draft_extension_launched"
        case Posted     = "wpios_draft_extension_posted"
        case Canceled   = "wpios_draft_extension_canceled"
        case Error      = "wpios_draft_extension_error"
    }
}
