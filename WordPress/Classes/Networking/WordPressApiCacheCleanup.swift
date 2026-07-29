import Foundation
import WordPressAPI
import WordPressAPIInternal
import WordPressApiCache
import WordPressCore
import WordPressData

enum WordPressApiCacheCleanup {
    static func removeCachedData(for blog: Blog) {
        removeCachedData(for: [blog])
    }

    static func removeCachedData(for blogs: Set<Blog>) {
        removeCachedData(for: Array(blogs))
    }

    private static func removeCachedData(for blogs: [Blog]) {
        let cache: WordPressApiCache
        do {
            guard let existingCache = try WordPressApiCache.openExistingOnDiskCache() else {
                return
            }
            cache = existingCache
        } catch {
            Loggers.app.error("Failed to open WordPress API cache for cleanup: \(error)")
            return
        }

        for blog in blogs {
            do {
                // `restApiRootURL` remains after an Atomic site's application
                // password is removed, so it records that direct transport was
                // configured without requiring the credential itself.
                let isDirect = !blog.isHostedAtWPcom || (blog.isAtomic && blog.restApiRootURL != nil)
                if isDirect {
                    _ = try cache.removeSelfHostedSite(url: blog.getUrl())
                } else if let siteID = blog.dotComID?.intValue {
                    _ = try cache.removeWordpressComSite(siteId: WpComSiteId(siteID))
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
