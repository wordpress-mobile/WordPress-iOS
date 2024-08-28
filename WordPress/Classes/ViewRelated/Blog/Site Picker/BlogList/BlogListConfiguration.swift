import Foundation

struct BlogListConfiguration {
    var shouldHideRecentSites = false
    var shouldHideSelfHostedSites = false
    var shouldHideBlogsNotSupportingDomains = false
    var analyticsSource: String?

    static let defaultConfig: BlogListConfiguration = .init()
}
