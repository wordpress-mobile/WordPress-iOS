import Foundation

@objc class AppConfiguration: NSObject, TargetConfiguration {
    @objc static let isJetpack: Bool = false
    @objc static let allowsConnectSite: Bool = true
}
