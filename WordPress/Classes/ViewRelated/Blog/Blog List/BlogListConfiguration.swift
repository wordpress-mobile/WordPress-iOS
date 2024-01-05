import Foundation

@objc class BlogListConfiguration: NSObject {
    @objc var shouldShowCancelButton: Bool
    @objc var shouldShowNavBarButtons: Bool
    @objc var navigationTitle: String
    /// Title shown on next page's back button
    @objc var backButtonTitle: String
    @objc var shouldHideSelfHostedSites: Bool
    @objc var shouldHideBlogsNotSupportingDomains: Bool
    @objc var analyticsSource: String?

    init(
        shouldShowCancelButton: Bool,
        shouldShowNavBarButtons: Bool,
        navigationTitle: String,
        backButtonTitle: String,
        shouldHideSelfHostedSites: Bool,
        shouldHideBlogsNotSupportingDomains: Bool,
        analyticsSource: String? = nil
    ) {
        self.shouldShowCancelButton = shouldShowCancelButton
        self.shouldShowNavBarButtons = shouldShowNavBarButtons
        self.navigationTitle = navigationTitle
        self.backButtonTitle = backButtonTitle
        self.shouldHideSelfHostedSites = shouldHideSelfHostedSites
        self.shouldHideBlogsNotSupportingDomains = shouldHideBlogsNotSupportingDomains
        self.analyticsSource = analyticsSource
        super.init()
    }

    static let defaultConfig: BlogListConfiguration = .init(shouldShowCancelButton: true,
                                                            shouldShowNavBarButtons: true,
                                                            navigationTitle: Strings.defaultNavigationTitle,
                                                            backButtonTitle: Strings.defaultBackButtonTitle,
                                                            shouldHideSelfHostedSites: false,
                                                            shouldHideBlogsNotSupportingDomains: false)

    private enum Strings {
        static let defaultNavigationTitle = NSLocalizedString("My Sites", comment: "Title for site picker screen.")
        static let defaultBackButtonTitle = NSLocalizedString("Switch Site", comment: "Title for back button that leads to the site picker screen.")
    }
}
