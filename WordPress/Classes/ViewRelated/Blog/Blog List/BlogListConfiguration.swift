import Foundation

struct BlogListConfiguration {
    var shouldHideSelfHostedSites: Bool
    var shouldHideBlogsNotSupportingDomains: Bool
    var analyticsSource: String?

    static let defaultConfig: BlogListConfiguration = .init(
        shouldHideSelfHostedSites: false,
        shouldHideBlogsNotSupportingDomains: false
    )
}
