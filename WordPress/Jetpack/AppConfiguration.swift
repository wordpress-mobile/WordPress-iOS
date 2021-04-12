import Foundation

@objc class AppConfiguration: NSObject {
    @objc static let isJetpack: Bool = true
    @objc static let allowsNewPostShortcut: Bool = false
    @objc static let allowsConnectSite: Bool = false
    @objc static let allowSiteCreation: Bool = false
}
