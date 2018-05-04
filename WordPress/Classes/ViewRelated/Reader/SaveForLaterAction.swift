import WordPressFlux

final class SaveForLaterAction: PostAction {
    private struct Strings {
        static let postSaved = NSLocalizedString("Post saved.", comment: "Title of the notification presented in Reader when a post is saved for later")
        static let viewAll = NSLocalizedString("View All", comment: "Button in the notification presented in Reader when a post is saved for later")
    }

    func execute(with post: ReaderPost, context: NSManagedObjectContext ) {
        toggleSavedForLater(post, context: context)
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

    private func toggleSavedForLater(_ post: ReaderPost, context: NSManagedObjectContext) {
        // TODO. We are still dealing with mocks, this will have to be updated when the coredata model is updated
        post.isSavedForLater() ? remove(post, context: context) : save(post, context: context)
    }

    private func save(_ post: ReaderPost, context: NSManagedObjectContext) {
        let readerPostService = ReaderPostService(managedObjectContext: context)
        //readerPostService.toggleSavedForLater(post)
        let savedForLaterService = MockSaveForLaterService()
        savedForLaterService.add(post)
    }

    private func remove(_ post: ReaderPost, context: NSManagedObjectContext) {
        let savedForLaterService = MockSaveForLaterService()
        savedForLaterService.remove(post)
    }
}
