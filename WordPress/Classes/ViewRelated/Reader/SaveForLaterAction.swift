import WordPressFlux

final class SaveForLaterAction: PostAction {
    private struct Strings {
        static let postSaved = NSLocalizedString("Post saved.", comment: "Title of the notification presented in Reader when a post is saved for later")
        static let viewAll = NSLocalizedString("View All", comment: "Button in the notification presented in Reader when a post is saved for later")
    }

    func execute(with post: ReaderPost) {
        toggleSavedForLater(post)
        presentNotice()
    }

    private func presentNotice() {
        let notice = Notice(title: Strings.postSaved,
                            actionTitle: Strings.viewAll,
                            actionHandler: {
                                print("Howdy!")
        })

        ActionDispatcher.dispatch(NoticeAction.post(notice))
    }

    private func toggleSavedForLater(_ post: ReaderPost) {
        // TODO. We are still dealing with mocks, this will have to be updated when the coredata model is updated
        post.isSavedForLater() ? remove(post) : save(post)
    }

    private func save(_ post: ReaderPost) {
        let savedForLaterService = MockSaveForLaterService()
        savedForLaterService.add(post)
    }

    private func remove(_ post: ReaderPost) {
        let savedForLaterService = MockSaveForLaterService()
        savedForLaterService.remove(post)
    }
}
