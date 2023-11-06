import Foundation

@objc class BlogListConfiguration: NSObject {
    @objc var shouldShowCancelButton: Bool

    init(shouldShowCancelButton: Bool) {
        self.shouldShowCancelButton = shouldShowCancelButton
        super.init()
    }

    static let defaultConfig: BlogListConfiguration = .init(shouldShowCancelButton: true)
}
