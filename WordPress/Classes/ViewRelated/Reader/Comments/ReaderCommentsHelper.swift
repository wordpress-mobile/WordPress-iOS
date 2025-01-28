import Foundation

/// A collection of utilities for managing rendering for comments.
@objc class ReaderCommentsHelper: NSObject {
    private var contentHeights: [TaggedManagedObjectID<Comment>: CGFloat] = [:]

    func getCachedContentHeight(for commentID: TaggedManagedObjectID<Comment>) -> CGFloat? {
        contentHeights[commentID]
    }

    func setCachedContentHeight(_ height: CGFloat, for commentID: TaggedManagedObjectID<Comment>) {
        contentHeights[commentID] = height
    }
}
