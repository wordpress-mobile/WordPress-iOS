import Foundation
import WordPressKit

/// Service allowing updating of homepage settings
///
struct HomepageSettingsService {
    public enum ResponseError: Error {
        case decodingFailed
    }

    let blog: Blog

    fileprivate let context: NSManagedObjectContext
    fileprivate let remote: HomepageSettingsServiceRemote
    fileprivate let siteID: Int

    init?(blog: Blog, context: NSManagedObjectContext) {
        guard let api = blog.wordPressComRestApi(), let dotComID = blog.dotComID as? Int else {
            return nil
        }

        self.remote = HomepageSettingsServiceRemote(wordPressComRestApi: api)
        self.siteID = dotComID
        self.blog = blog
        self.context = context
    }

    public func setHomepageType(_ type: HomepageType,
                                withPostsPageID postsPageID: Int? = nil,
                                homePageID: Int? = nil,
                                success: @escaping () -> Void,
                                failure: @escaping (Error) -> Void) {

        // Keep track of the original settings in case we need to revert
        let originalHomepageType = blog.homepageType
        let originalHomePageID = blog.homepagePageID
        let originalPostsPageID = blog.homepagePostsPageID

        switch type {
        case .page:
            blog.homepageType = .page
            if let postsPageID = postsPageID {
                blog.homepagePostsPageID = postsPageID
                if postsPageID == originalHomePageID {
                    // Don't allow the same page to be set for both values
                    blog.homepagePageID = 0
                }
            }
            if let homePageID = homePageID {
                blog.homepagePageID = homePageID
                if homePageID == originalPostsPageID {
                    // Don't allow the same page to be set for both values
                    blog.homepagePostsPageID = 0
                }
            }
        case .posts:
            blog.homepageType = .posts
        }

        ContextManager.sharedInstance().save(context)

        remote.setHomepageType(type: type.remoteType,
                               for: siteID,
                               withPostsPageID: blog.homepagePostsPageID,
                               homePageID: blog.homepagePageID,
                               success: success,
                               failure: { error in
                                self.context.performAndWait {
                                    self.blog.homepageType = originalHomepageType
                                    self.blog.homepagePostsPageID = originalPostsPageID
                                    self.blog.homepagePageID = originalHomePageID
                                    ContextManager.sharedInstance().saveContextAndWait(self.context)
                                }

                                failure(error)
        })
    }
}
