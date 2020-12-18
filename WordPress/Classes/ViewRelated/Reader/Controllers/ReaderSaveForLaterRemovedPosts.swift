final class ReaderSaveForLaterRemovedPosts {
    private var removedPosts: [ReaderPost]

    init() {
        removedPosts = []
    }

    func add(_ post: ReaderPost) {
        removedPosts.append(post)
    }

    func remove(_ post: ReaderPost) {
        guard let index = removedPosts.firstIndex(of: post) else {
            return
        }

        removedPosts.remove(at: index)
    }

    func contains(_ post: ReaderPost) -> Bool {
        return removedPosts.contains(post)
    }

    func all() -> [ReaderPost] {
        return removedPosts
    }
}
