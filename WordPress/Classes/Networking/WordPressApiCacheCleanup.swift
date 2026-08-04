import Foundation
import WordPressAPI
import WordPressAPIInternal
import WordPressApiCache
import WordPressCore
import WordPressData

extension BlogService {
    @objc(removeWordPressApiCachedDataForBlog:)
    public func removeWordPressApiCachedData(for blog: Blog) {
        WordPressApiCache.shared.removeCachedData(for: blog)
    }
}

extension WordPressApiCache {
    func removeCachedData(for blog: Blog) {
        removeCachedData(for: [blog])
    }

    func removeCachedData(for blogs: Set<Blog>) {
        removeCachedData(for: Array(blogs))
    }

    private func removeCachedData(for blogs: [Blog]) {
        for blog in blogs {
            do {
                // `restApiRootURL` remains after an Atomic site's application
                // password is removed, so it records that direct transport was
                // configured without requiring the credential itself.
                let isDirect = !blog.isHostedAtWPcom || (blog.isAtomic && blog.restApiRootURL != nil)
                if isDirect {
                    try removeSelfHostedSite(url: blog.getUrl())
                } else if let siteID = blog.dotComID?.intValue {
                    try removeWordpressComSite(siteId: WpComSiteId(siteID))
                } else {
                    Loggers.app.error(
                        "Skipped WordPress API cache cleanup because the site's durable metadata is incomplete"
                    )
                }
            } catch {
                Loggers.app.error("Failed to remove WordPress API cached data: \(error)")
            }
        }
    }
}
