import WordPressFlux

final class SaveForLaterAction: PostAction {
    private struct Strings {
        static let postSaved = NSLocalizedString("Post saved.", comment: "Title of the notification presented in Reader when a post is saved for later")
        static let viewAll = NSLocalizedString("View All", comment: "Button in the notification presented in Reader when a post is saved for later")
    }

    func execute(with post: ReaderPost) {
        //1.- Present notice
        presentNotice()
        //2.- Mark post as saved for later (boolean flag in ReaderPost)
        //3.- Send post to the SaveForLaterService
        //4.- Present toast
    }

    private func presentNotice() {
        let notice = Notice(title: Strings.postSaved,
                            actionTitle: Strings.viewAll,
                            actionHandler: {
                                print("Howdy!")
        })

        ActionDispatcher.dispatch(NoticeAction.post(notice))
    }
}
