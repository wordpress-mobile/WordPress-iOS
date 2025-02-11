import Foundation
import WordPressReader

/// A collection of utilities for managing rendering for comments.
@MainActor
@objc class ReaderCommentsHelper: NSObject {
    private var contentHeights: [String: CGFloat] = [:]
    private let webViewContext = WebCommentContentRenderer.Context()

    func makeWebRenderer() -> WebCommentContentRenderer {
        let renderer = WebCommentContentRenderer(context: webViewContext)
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
}
