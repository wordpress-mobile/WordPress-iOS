import Foundation
import WordPressReader

/// A collection of utilities for managing rendering for comments.
@MainActor
@objc class ReaderCommentsHelper: NSObject {
    private var contentHeights: [TaggedManagedObjectID<Comment>: CGFloat] = [:]
    private let webViewContext = WebCommentContentRenderer.Context()

    func makeWebRenderer() -> WebCommentContentRenderer {
        let renderer = WebCommentContentRenderer(context: webViewContext)
        renderer.tintColor = UIAppColor.primary
        return renderer
    }

    func getCachedContentHeight(for commentID: TaggedManagedObjectID<Comment>) -> CGFloat? {
        contentHeights[commentID]
    }

    func setCachedContentHeight(_ height: CGFloat, for commentID: TaggedManagedObjectID<Comment>) {
        contentHeights[commentID] = height
    }
}
