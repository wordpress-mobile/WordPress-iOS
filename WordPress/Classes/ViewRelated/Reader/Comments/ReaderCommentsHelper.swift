import Foundation

/// A collection of utilities for managing rendering for comments.
@objc class ReaderCommentsHelper: NSObject {
    private var contentHeights: [TaggedManagedObjectID<Comment>: CGFloat] = [:]
    private let renderers = NSCache<Comment, WebCommentContentRenderer>()

    override init() {
        renderers.countLimit = 30
    }

    func getRenderer(for comment: Comment) -> WebCommentContentRenderer {
        if let renderer = renderers.object(forKey: comment) {
            return renderer
        }
        let renderer = WebCommentContentRenderer()
        renderers.setObject(renderer, forKey: comment)
        return renderer
    }

    func getCachedContentHeight(for commentID: TaggedManagedObjectID<Comment>) -> CGFloat? {
        contentHeights[commentID]
    }

    func setCachedContentHeight(_ height: CGFloat, for commentID: TaggedManagedObjectID<Comment>) {
        contentHeights[commentID] = height
    }
}
