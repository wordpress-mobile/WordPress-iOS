import Foundation


// MARK: - WordPress.com Site Info
//
class WordPressComSiteInfo {

    /// Site's Name!
    ///
    let name: String

    /// Tagline.
    ///
    let tagline: String

    /// Public URL.
    ///
    let url: String

    /// Indicates if Jetpack is available, or not,
    ///
    let hasJetpack: Bool

    /// URL of the Site's Blavatar.
    ///
    let icon: String



    /// Initializes the current SiteInfo instance with a raw dictionary.
    ///
    init(remote: [AnyHashable: Any]) {
        name        = remote["name"] as? String         ?? ""
        tagline     = remote["description"] as? String  ?? ""
        url         = remote["URL"] as? String          ?? ""
        hasJetpack  = remote["jetpack"] as? Bool        ?? false
        icon        = remote["icon.img"] as? String     ?? ""
    }
}
