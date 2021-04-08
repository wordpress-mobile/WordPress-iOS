import Foundation

@objc class AppConfiguration: NSObject {
    @objc static let isJetpack: Bool = false
    @objc static let allowsConnectSite: Bool = true
    @objc static let allowSiteCreation: Bool = true
}
