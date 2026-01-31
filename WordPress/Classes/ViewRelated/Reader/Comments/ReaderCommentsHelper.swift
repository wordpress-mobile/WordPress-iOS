import Foundation
import CoreData
import WordPressReader
import WordPressUI

/// A collection of utilities for managing rendering for comments.
@MainActor
@objc class ReaderCommentsHelper: NSObject {
    private var contentHeights: [String: CGFloat] = [:]
    private var expandedComments: Set<NSManagedObjectID> = []

    var isP2Site: Bool = false

    func makeWebRenderer() -> WebCommentContentRenderer {
        let renderer = WebCommentContentRenderer()
        renderer.tintColor = UIAppColor.primary
        return renderer
    }

    func getCachedContentHeight(for comment: String) -> CGFloat? {
        contentHeights[comment]
    }

    func setCachedContentHeight(_ height: CGFloat, for comment: String) {
        contentHeights[comment] = height
    }

    func resetCachedContentHeights() {
        contentHeights.removeAll()
    }

    func isCommentExpanded(_ commentID: NSManagedObjectID) -> Bool {
        expandedComments.contains(commentID)
    }

    func setCommentExpanded(_ commentID: NSManagedObjectID, isExpanded: Bool) {
        if isExpanded {
            expandedComments.insert(commentID)
        } else {
            expandedComments.remove(commentID)
        }
    }
}
