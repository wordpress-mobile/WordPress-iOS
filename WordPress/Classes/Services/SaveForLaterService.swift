protocol SaveForLaterService {
    func add(_ post: ReaderSavedForLaterPost)
    func remove(_ postId: NSNumber)
    func all() -> [ReaderSavedForLaterPost]
}

// MARK: - Mock. We make all the posts marked as saved for later just to keep going. This will be a property in the coredata model
extension ReaderPost {
    @available(*, deprecated: 1.0, message: "will soon become unavailable.")
    func isSavedForLater() -> Bool {
        return true
    }
}

final class MockSaveForLaterService: SaveForLaterService {
    func add(_ post: ReaderSavedForLaterPost) {
        commit(post)
    }

    func remove(_ postId: NSNumber) {
        //1.- Fetch ReaderSavedForLaterPost from cd store
        //2.- Remove it
    }

    func all() -> [ReaderSavedForLaterPost] {
        return [ReaderSavedForLaterPost()]
    }

    private func commit(_ serializedPost: ReaderSavedForLaterPost) {
        // Actually save to coredata
    }
}
