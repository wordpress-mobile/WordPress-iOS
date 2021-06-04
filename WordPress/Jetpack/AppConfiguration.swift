import Foundation

/**
 * Jetpack Configuration
 */
@objc class AppConfiguration: NSObject {
    @objc static let isJetpack: Bool = true
    @objc static let allowsNewPostShortcut: Bool = false
    @objc static let allowsConnectSite: Bool = false
    @objc static let allowSiteCreation: Bool = false
    @objc static let allowSignUp: Bool = false
    @objc static let allowsCustomAppIcons: Bool = false
    @objc static let showsReader: Bool = false
    @objc static let showsCreateButton: Bool = false
    @objc static let showsQuickActions: Bool = false
    @objc static let showsFollowedSitesSettings: Bool = false
    @objc static let showsWhatIsNew: Bool = false
}
