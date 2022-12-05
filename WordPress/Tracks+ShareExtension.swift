import Foundation


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

    fileprivate func trackExtensionEvent(_ event: ExtensionEvents, properties: [String: AnyObject]? = nil) {
        track(event.rawValue, properties: properties)
    }

    // MARK: - Private Enums

    fileprivate enum ExtensionEvents: String {
        case launched       = "share_extension_launched"
        case posted         = "share_extension_posted"
        case tagsOpened     = "share_extension_tags_opened"
        case tagsSelected   = "share_extension_tags_selected"
        case canceled       = "share_extension_canceled"
        case error          = "share_extension_error"
        case categoriesOpened   = "share_extension_categories_opened"
        case categoriesSelected = "share_extension_categories_selected"
        case postTypeOpened   = "share_extension_post_type_opened"
        case postTypeSelected = "share_extension_post_type_selected"
    }
}
