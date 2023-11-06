import Foundation

@objc class BlogListConfiguration: NSObject {
    var shouldShowCancelButton: Bool

    init(shouldShowCancelButton: Bool) {
        self.shouldShowCancelButton = shouldShowCancelButton
        super.init()
    }

    @objc static let defaultConfig: BlogListConfiguration = .init(shouldShowCancelButton: true)
}
