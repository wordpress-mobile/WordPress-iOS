final class ReaderSavedPostCellActions: ReaderPostCellActions {
    /// Posts that have been removed but not yet discarded
    private var removedPosts = ReaderSaveForLaterRemovedPosts()

    override func readerCell(_ cell: ReaderPostCardCell, saveActionForProvider provider: ReaderPostContentProvider) {
        if let post = provider as? ReaderPost {
            removedPosts.add(post)
        }

        super.readerCell(cell, saveActionForProvider: provider)
    }

    func contains(_ post: ReaderPost) -> Bool {
        return removedPosts.contains(post)
    }

    func remove(_ post: ReaderPost) {
        removedPosts.remove(post)
    }
}
