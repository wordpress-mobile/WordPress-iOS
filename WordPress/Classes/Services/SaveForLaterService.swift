protocol SaveForLaterService {
    func add(_ post: ReaderPost)
    func remove(_ post: ReaderPost)
    func all() -> [ReaderSavedForLaterPost]
}

fileprivate final class ReaderPostSerialiser {
    func serialize(post: ReaderPost) -> ReaderSavedForLaterPost {
        return ReaderSavedForLaterPost()
    }
}


final class MockSaveForLaterService: SaveForLaterService {
    private let serialiser = ReaderPostSerialiser()

    func add(_ post: ReaderPost) {
        let serialisedPost = serialiser.serialize(post: post)
        commit(serialisedPost)
    }

    func remove(_ post: ReaderPost) {
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
