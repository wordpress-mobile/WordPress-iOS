import Foundation
import WordPressKit

/// Service allowing updating of homepage settings
///
struct HomepageSettingsService {
    let blog: Blog

    fileprivate let coreDataStack: CoreDataStack
    fileprivate let remote: HomepageSettingsServiceRemote
    fileprivate let siteID: Int

    init?(blog: Blog, coreDataStack: CoreDataStack) {
        guard let api = blog.wordPressComRestApi(), let dotComID = blog.dotComID as? Int else {
            return nil
        }

        self.remote = HomepageSettingsServiceRemote(wordPressComRestApi: api)
        self.siteID = dotComID
        self.blog = blog
        self.coreDataStack = coreDataStack
    }

    public func setHomepageType(_ type: HomepageType,
                                withPostsPageID postsPageID: Int? = nil,
                                homePageID: Int? = nil,
                                success: @escaping () -> Void,
                                failure: @escaping (Error) -> Void) {
        var originalHomepageType: HomepageType?
        var originalHomePageID: Int?
        var originalPostsPageID: Int?
        coreDataStack.performAndSave({ context in
            guard let blog = Blog.lookup(withObjectID: self.blog.objectID, in: context) else {
                return
            }

            // Keep track of the original settings in case we need to revert
            originalHomepageType = blog.homepageType
            originalHomePageID = blog.homepagePageID
            originalPostsPageID = blog.homepagePostsPageID

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
        }, completion: {
            remote.setHomepageType(
                type: type.remoteType,
                for: siteID,
                withPostsPageID: blog.homepagePostsPageID,
                homePageID: blog.homepagePageID,
                success: success,
                failure: { error in
                    self.coreDataStack.performAndSave({ context in
                        guard let blog = Blog.lookup(withObjectID: self.blog.objectID, in: context) else {
                            return
                        }
                        blog.homepageType = originalHomepageType
                        blog.homepagePostsPageID = originalPostsPageID
                        blog.homepagePageID = originalHomePageID
                    }, completion: {
                        failure(error)
                    }, on: .main)
                }
            )
        }, on: .main)


    }
}
