import Foundation

/**
 * Jetpack Configuration
 */
@objc class AppConfiguration: NSObject {
    @objc static let isJetpack: Bool = true
    @objc static let isWordPress: Bool = false
    @objc static let showJetpackSitesOnly: Bool = false
    @objc static let allowsNewPostShortcut: Bool = true
    @objc static let allowsConnectSite: Bool = true
    @objc static let allowSiteCreation: Bool = true
    @objc static let allowSignUp: Bool = true
    @objc static let allowsCustomAppIcons: Bool = false
    @objc static let allowsDomainRegistration: Bool = true
    @objc static let showsReader: Bool = true
    @objc static let showsCreateButton: Bool = true
    @objc static let showAddSelfHostedSiteButton: Bool = false
    @objc static let showsQuickActions: Bool = true
    @objc static let showsFollowedSitesSettings: Bool = true
    @objc static let showsWhatIsNew: Bool = false
    @objc static let qrLoginEnabled: Bool = true
}
