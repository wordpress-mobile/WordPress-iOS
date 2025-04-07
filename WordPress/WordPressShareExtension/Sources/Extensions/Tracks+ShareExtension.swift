import Foundation
import TracksMini

/// This extension implements helper tracking methods, meant for Share Extension Usage.
///
extension Tracks {
    // MARK: - Public Methods

    public func trackExtensionLaunched(_ wpcomAvailable: Bool) {
        let properties = ["is_configured_dotcom": wpcomAvailable]
        trackExtensionEvent(.launched, properties: properties as [String: AnyObject])
    }

    public func trackExtensionPosted(_ status: String) {
        let properties = ["post_status": status]
        trackExtensionEvent(.posted, properties: properties as [String: AnyObject])
    }

    public func trackExtensionError(_ error: NSError) {
        let properties = ["error_code": String(error.code), "error_domain": error.domain, "error_description": error.description]
        trackExtensionEvent(.error, properties: properties as [String: AnyObject])
    }

    public func trackExtensionCancelled() {
        trackExtensionEvent(.canceled)
    }

    public func trackExtensionTagsOpened() {
        trackExtensionEvent(.tagsOpened)
    }

    public func trackExtensionTagsSelected(_ tags: String) {
        let properties = ["selected_tags": tags]
        trackExtensionEvent(.tagsSelected, properties: properties as [String: AnyObject])
    }

    public func trackExtensionCategoriesOpened() {
        trackExtensionEvent(.categoriesOpened)
    }

    public func trackExtensionCategoriesSelected(_ categories: String) {
        let properties = ["categories_tags": categories]
        trackExtensionEvent(.categoriesSelected, properties: properties as [String: AnyObject])
    }

    public func trackExtensionPostTypeOpened() {
        trackExtensionEvent(.postTypeOpened)
    }

    public func trackExtensionPostTypeSelected(_ postType: String) {
        let properties = ["post_type": postType]
        trackExtensionEvent(.postTypeSelected, properties: properties as [String: AnyObject])
    }

    // MARK: - Private Helpers

    private func trackExtensionEvent(_ event: ExtensionEvents, properties: [String: AnyObject]? = nil) {
        guard let namespace = Bundle.main.object(forInfoDictionaryKey: "WPAppExtensionType") as? String else {
            return assertionFailure("WPAppExtensionType missing")
        }
        let eventName = "\(namespace)_extension_\(event.rawValue)"
        track(eventName, properties: properties)
    }
}

private enum ExtensionEvents: String {
    case launched = "launched"
    case posted = "posted"
    case tagsOpened = "tags_opened"
    case tagsSelected = "tags_selected"
    case canceled = "canceled"
    case error = "exror"
    case categoriesOpened = "categories_opened"
    case categoriesSelected = "categories_selected"
    case postTypeOpened = "post_type_opened"
    case postTypeSelected = "post_type_selected"
}
