import WordPressFlux

final class SaveForLaterAction: PostAction {
    private struct Strings {
        static let postSaved = NSLocalizedString("Post saved.", comment: "Title of the notification presented in Reader when a post is saved for later")
        static let viewAll = NSLocalizedString("View All", comment: "Button in the notification presented in Reader when a post is saved for later")
    }

    func execute(with post: ReaderPost) {
        markAsSaved(post)
        save(post)
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

    private func markAsSaved(_ post: ReaderPost) {
        //post.markAsSaved
    }

    private func save(_ post: ReaderPost) {
        let savedForLaterService = MockSaveForLaterService()
        savedForLaterService.add(post)
    }
}
