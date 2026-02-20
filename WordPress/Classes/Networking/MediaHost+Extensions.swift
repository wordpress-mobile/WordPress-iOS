import Foundation
import WordPressData

extension MediaHost {

    // MARK: - MediaHost (AbstractPost)

    init(_ post: AbstractPost) {
        self.init(post.blog)
   }

    // MARK: - MediaHost (Blog)

    init(_ blog: Blog) {
        self.init(
            isAccessibleThroughWPCom: blog.isAccessibleThroughWPCom(),
            isPrivate: blog.isPrivate,
            isAtomic: blog.isAtomic,
            siteID: blog.dotComID?.intValue,
            username: blog.effectiveUsername,
            authToken: blog.authToken,
            failure: { error in
                WordPressAppDelegate.crashLogging?.logError(error)
            }
        )
   }

    // MARK: - MediaHost (ReaderPost)

    init(_ post: ReaderPost) {
        let isAccessibleThroughWPCom = post.isWPCom || post.isJetpack

        // This is the only way in which we can obtain the username and authToken here.
        // It'd be nice if all data was associated with an account instead, for transparency
        // and cleanliness of the code - but this'll have to do for now.

        // We allow a nil account in case the user connected only self-hosted sites.
        let account = try? WPAccount.lookupDefaultWordPressComAccount(in: ContextManager.shared.mainContext)
        let username = account?.username
        let authToken = account?.authToken

        self.init(
            isAccessibleThroughWPCom: isAccessibleThroughWPCom,
            isPrivate: post.isBlogPrivate,
            isAtomic: post.isBlogAtomic,
            siteID: post.siteID?.intValue,
            username: username,
            authToken: authToken,
            failure: { error in
                WordPressAppDelegate.crashLogging?.logError(error)
            }
        )
    }
}
