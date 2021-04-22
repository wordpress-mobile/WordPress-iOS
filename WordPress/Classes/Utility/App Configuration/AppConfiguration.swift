import Foundation

/**
 * WordPress Configuration
 */
@objc class AppConfiguration: NSObject {
    @objc static let isJetpack: Bool = false
    @objc static let allowsNewPostShortcut: Bool = true
    @objc static let allowsConnectSite: Bool = true
    @objc static let allowSiteCreation: Bool = true
    @objc static let allowSignUp: Bool = true
    @objc static let allowsCustomAppIcons: Bool = true
    @objc static let showsReader: Bool = true
    @objc static let showsCreateButton: Bool = true
    @objc static let showsJetpackSectionHeader: Bool = true
}
