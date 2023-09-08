import Foundation

/**
 * Jetpack Configuration
 * - Warning:
 * This configuration class has a **WordPress** counterpart in the WordPress bundle.
 * Make sure to keep them in sync to avoid build errors when building the WordPress target.
 */
@objc class AppConfiguration: NSObject {
    @objc static let isJetpack: Bool = true
    @objc static let isWordPress: Bool = false
    @objc static let showJetpackSitesOnly: Bool = false
    @objc static let allowsNewPostShortcut: Bool = true
    @objc static let allowsConnectSite: Bool = true
    @objc static let allowSiteCreation: Bool = true
    @objc static let allowSignUp: Bool = true
    @objc static let allowsCustomAppIcons: Bool = true
    @objc static let allowsDomainRegistration: Bool = true
    @objc static let showsCreateButton: Bool = true
    @objc static let showAddSelfHostedSiteButton: Bool = true
    @objc static let showsQuickActions: Bool = true
    @objc static let showsFollowedSitesSettings: Bool = true
    @objc static let showsWhatIsNew: Bool = true
    @objc static let qrLoginEnabled: Bool = true
    @objc static let bloggingPromptsEnabled = true
}
