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
    func add(_ post: ReaderPost) {
        print("=== adding post to the service ====")
        //1.- Transform ReaderPost into SavedForLaterPost
        //2.- Save SavedForLaterPost to coredata
    }

    func remove(_ post: ReaderPost) {
        print("=== remove post to the service ====")
        //1.- Transform ReaderPost into SavedForLaterPost
        //2.- Remove SavedForLaterPost from coredata
    }

    func all() -> [ReaderSavedForLaterPost] {
        return [ReaderSavedForLaterPost()]
    }
}
