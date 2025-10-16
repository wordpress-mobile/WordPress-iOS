import Foundation
import CoreData
import WordPressKit

public extension Post {

    @NSManaged var commentCount: NSNumber?
    @NSManaged var disabledPublicizeConnections: [NSNumber: [String: String]]?
    @NSManaged var likeCount: NSNumber?
    @NSManaged var postFormat: String?
    @NSManaged var postType: String?
    @NSManaged var publicID: String?
    @NSManaged var publicizeMessage: String?
    @NSManaged var publicizeMessageID: String?
    @NSManaged var tags: String?
    @NSManaged var categories: Set<PostCategory>?
    @NSManaged var isStickyPost: Bool
    @NSManaged var commentsStatus: String?
    @NSManaged var pingsStatus: String?

    // If the post is created as an answer to a Blogging Prompt, the promptID is stored here.
    @NSManaged var bloggingPromptID: String?

    // These were added manually, since the code generator for Swift is not generating them.
    //
    @NSManaged func addCategoriesObject(_ value: PostCategory)
    @NSManaged func removeCategoriesObject(_ value: PostCategory)
    @NSManaged func addCategories(_ values: Set<PostCategory>)
    @NSManaged func removeCategories(_ values: Set<PostCategory>)
}

extension Post {
    public var allowComments: Bool {
        get { commentsStatus != RemotePostDiscussionState.closed.rawValue }
        set { commentsStatus = (newValue ? RemotePostDiscussionState.open : .closed).rawValue }
    }

    public var allowPings: Bool {
        get { pingsStatus != RemotePostDiscussionState.closed.rawValue }
        set { pingsStatus = (newValue ? RemotePostDiscussionState.open : .closed).rawValue }
    }
}
