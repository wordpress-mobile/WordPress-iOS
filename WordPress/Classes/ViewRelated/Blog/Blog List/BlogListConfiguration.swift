import Foundation

@objc class BlogListConfiguration: NSObject {
    @objc var shouldShowCancelButton: Bool
    @objc var shouldShowNavBarButtons: Bool

    init(shouldShowCancelButton: Bool, shouldShowNavBarButtons: Bool) {
        self.shouldShowCancelButton = shouldShowCancelButton
        self.shouldShowNavBarButtons = shouldShowNavBarButtons
        super.init()
    }

    static let defaultConfig: BlogListConfiguration = .init(shouldShowCancelButton: true,
                                                            shouldShowNavBarButtons: true)
}
