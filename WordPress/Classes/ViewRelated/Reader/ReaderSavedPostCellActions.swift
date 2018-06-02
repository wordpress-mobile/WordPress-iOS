protocol ReaderSavedPostCellActionsDelegate: class {
    func willRemove(_ cell: ReaderPostCardCell)
}


/// Specialises ReaderPostCellActions to provide specific overrides for the ReaderSavedPostsViewController
final class ReaderSavedPostCellActions: ReaderPostCellActions {
    /// Posts that have been removed but not yet discarded
    private var removedPosts = ReaderSaveForLaterRemovedPosts()

    weak var delegate: ReaderSavedPostCellActionsDelegate?

    override func readerCell(_ cell: ReaderPostCardCell, saveActionForProvider provider: ReaderPostContentProvider) {
        if let post = provider as? ReaderPost {
            removedPosts.add(post)
        }
        delegate?.willRemove(cell)
    }

    func postIsRemoved(_ post: ReaderPost) -> Bool {
        return removedPosts.contains(post)
    }

    func restoreUnsavedPost(_ post: ReaderPost) {
        removedPosts.remove(post)
    }

    func clearRemovedPosts() {
        let allRemovedPosts = removedPosts.all()
        for post in allRemovedPosts {
            toggleSavedForLater(for: post)
        }
        removedPosts = ReaderSaveForLaterRemovedPosts()
    }
}
