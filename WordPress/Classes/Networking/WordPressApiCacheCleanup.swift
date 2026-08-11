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
            // A site is cached under its self-hosted URL, its WordPress.com
            // site ID, or (for Atomic) both. Removal is a no-op when the key
            // is absent, so clear every key the site has instead of inferring
            // which representation applies.
            if let url = try? blog.getUrl() {
                do {
                    try removeSelfHostedSite(url: url)
                } catch {
                    Loggers.app.error("Failed to remove self-hosted API cached data: \(error)")
                }
            }
            if let siteID = blog.dotComID?.intValue {
                do {
                    try removeWordpressComSite(siteId: WpComSiteId(siteID))
                } catch {
                    Loggers.app.error("Failed to remove WordPress.com API cached data: \(error)")
                }
            }
        }
    }
}
