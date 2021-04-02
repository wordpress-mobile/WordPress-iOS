import Foundation

@objc class AppConfiguration: NSObject, TargetConfiguration {
    @objc static let isJetpack: Bool = true
    @objc static let allowsNewPostShortcut: Bool = false
}
