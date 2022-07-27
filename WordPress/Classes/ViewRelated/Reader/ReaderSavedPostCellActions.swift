protocol ReaderSavedPostCellActionsDelegate: AnyObject {
    func willRemove(_ cell: ReaderPostCardCell)
}


/// Specialises ReaderPostCellActions to provide specific overrides for the ReaderSavedPostsViewController
final class ReaderSavedPostCellActions: ReaderPostCellActions {

    override func readerCell(_ cell: ReaderPostCardCell, saveActionForProvider provider: ReaderPostContentProvider) {
        if let post = provider as? ReaderPost {
            removedPosts.add(post)
        }
        savedPostsDelegate?.willRemove(cell)
    }
}
