import Foundation

/**
 * WordPress Configuration
 * - Warning:
 * This configuration class has a **Jetpack** counterpart in the Jetpack bundle.
 * Make sure to keep them in sync to avoid build errors when building the Jetpack target.
 */
@objc class AppConfiguration: NSObject {
    @objc static let isJetpack: Bool = false
    @objc static let isWordPress: Bool = true
    @objc static let showJetpackSitesOnly: Bool = false
    @objc static let allowsNewPostShortcut: Bool = true
    @objc static let allowsConnectSite: Bool = true
    @objc static let allowSiteCreation: Bool = true
    @objc static let allowSignUp: Bool = true
    @objc static let allowsCustomAppIcons: Bool = true
    @objc static let allowsDomainRegistration: Bool = false
    @objc static let showsCreateButton: Bool = true
    @objc static let showAddSelfHostedSiteButton: Bool = true
    @objc static let showsQuickActions: Bool = true
    @objc static let showsFollowedSitesSettings: Bool = true
    @objc static let showsWhatIsNew: Bool = true
    @objc static let qrLoginEnabled: Bool = false
    @objc static let statsRevampV2Enabled: Bool = false
    @objc static let personalizeHomeTabEnabled: Bool = false
}
