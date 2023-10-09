protocol ReaderSavedPostCellActionsDelegate: AnyObject {
    func willRemove(_ cell: OldReaderPostCardCell)
}


/// Specialises ReaderPostCellActions to provide specific overrides for the ReaderSavedPostsViewController
final class ReaderSavedPostCellActions: ReaderPostCellActions {

    override func readerCell(_ cell: OldReaderPostCardCell, saveActionForProvider provider: ReaderPostContentProvider) {
        if let post = provider as? ReaderPost {
            removedPosts.add(post)
        }
        savedPostsDelegate?.willRemove(cell)
    }
}
