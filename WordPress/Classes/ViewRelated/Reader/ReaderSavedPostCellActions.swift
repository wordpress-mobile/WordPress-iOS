protocol ReaderSavedPostCellActionsDelegate: class {
    func willRemove(_ cell: ReaderPostCardCell)
}

final class ReaderSavedPostCellActions: ReaderPostCellActions {
    /// Posts that have been removed but not yet discarded
    private var removedPosts = ReaderSaveForLaterRemovedPosts()

    weak var delegate: ReaderSavedPostCellActionsDelegate?

    override func readerCell(_ cell: ReaderPostCardCell, saveActionForProvider provider: ReaderPostContentProvider) {
        if let post = provider as? ReaderPost {
            removedPosts.add(post)
        }
        delegate?.willRemove(cell)
        //super.readerCell(cell, saveActionForProvider: provider)
    }

    func contains(_ post: ReaderPost) -> Bool {
        return removedPosts.contains(post)
    }

    func remove(_ post: ReaderPost) {
        removedPosts.remove(post)
    }

    func clear() {
        let allRemovedPosts = removedPosts.all()
        for post in allRemovedPosts {
            toggleSavedForLater(for: post)
        }
        removedPosts = ReaderSaveForLaterRemovedPosts()
    }
}
