import Foundation

/// This extension implements helper tracking methods, meant for Draft Action Extension usage.
///
extension Tracks {
    // MARK: - Public Methods

    public func trackExtensionLaunched(_ wpcomAvailable: Bool) {
        let properties = ["is_configured_dotcom": wpcomAvailable]
        trackExtensionEvent(.launched, properties: properties as [String: AnyObject]?)
    }

    public func trackExtensionPosted(_ status: String) {
        let properties = ["post_status": status]
        trackExtensionEvent(.posted, properties: properties as [String: AnyObject]?)
    }

    public func trackExtensionError(_ error: NSError) {
        let properties = ["error_code": String(error.code), "error_domain": error.domain, "error_description": error.description]
        trackExtensionEvent(.error, properties: properties as [String: AnyObject]?)
    }

    public func trackExtensionCancelled() {
        trackExtensionEvent(.canceled)
    }

    public func trackExtensionTagsOpened() {
        trackExtensionEvent(.tagsOpened)
    }

    public func trackExtensionTagsSelected(_ tags: String) {
        let properties = ["selected_tags": tags]
        trackExtensionEvent(.tagsSelected, properties: properties as [String: AnyObject]?)
    }

    // MARK: - Private Helpers

    fileprivate func trackExtensionEvent(_ event: ExtensionEvents, properties: [String: AnyObject]? = nil) {
        track(event.rawValue, properties: properties)
    }

    // MARK: - Private Enums

    fileprivate enum ExtensionEvents: String {
        case launched       = "wpios_draft_extension_launched"
        case posted         = "wpios_draft_extension_posted"
        case tagsOpened     = "wpios_draft_extension_tags_opened"
        case tagsSelected   = "wpios_draft_extension_tags_selected"
        case canceled       = "wpios_draft_extension_canceled"
        case error          = "wpios_draft_extension_error"
    }
}
