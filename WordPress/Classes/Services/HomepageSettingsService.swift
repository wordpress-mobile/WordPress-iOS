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

        let originalHomepageType = blog.homepageType

        switch type {
        case .page:
            blog.homepageType = .page
        case .posts:
            blog.homepageType = .posts
        }

        ContextManager.sharedInstance().save(context)

        remote.setHomepageType(type: type.remoteType,
                               for: siteID,
                               withPostsPageID: postsPageID,
                               homePageID: homePageID,
                               success: success,
                               failure: { error in
                                self.context.performAndWait {
                                    self.blog.homepageType = originalHomepageType
                                    ContextManager.sharedInstance().saveContextAndWait(self.context)
                                }

                                failure(error)
        })
    }
}
