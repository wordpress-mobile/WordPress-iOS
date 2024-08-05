import Foundation

struct BlogListConfiguration {
    var shouldHideSelfHostedSites = false
    var shouldHideBlogsNotSupportingDomains = false
    var analyticsSource: String?

    static let defaultConfig: BlogListConfiguration = .init()
}
