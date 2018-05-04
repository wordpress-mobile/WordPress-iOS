import WordPressFlux

final class SaveForLaterAction: PostAction {
    private struct Strings {
        static let postSaved = NSLocalizedString("Post saved.", comment: "Title of the notification presented in Reader when a post is saved for later")
        static let viewAll = NSLocalizedString("View All", comment: "Button in the notification presented in Reader when a post is saved for later")
        static let toggleError = NSLocalizedString("Could not unfollow site", comment: "Title of a prompt.")
    }

    func execute(with post: ReaderPost, context: NSManagedObjectContext ) {
        toggleSavedForLater(post, context: context)
    }

    private func toggleSavedForLater(_ post: ReaderPost, context: NSManagedObjectContext) {
        let readerPostService = ReaderPostService(managedObjectContext: context)
        readerPostService.toggleSavedForLater(for: post, success: { [weak self] in
                self?.presentSuccessNotice()
        }, failure: { [weak self] error in
            self?.presentErrorNotice(error)
        })
    }

    private func presentSuccessNotice() {
        let notice = Notice(title: Strings.postSaved,
                            feedbackType: .success,
                            actionTitle: Strings.viewAll,
                            actionHandler: {
                                self.showAll()
        })

        post(notice)
    }

    private func presentErrorNotice(_ error: Error?) {
        DDLogError("Could not toggle save for later: \(String(describing: error))")
        let notice = Notice(title: Strings.toggleError,
                            message: error?.localizedDescription,
                            feedbackType: .error)

        post(notice)
    }

    private func post(_ notice: Notice) {
        ActionDispatcher.dispatch(NoticeAction.post(notice))
    }

    private func showAll() {
        //Navigate to all saved for later
    }
}
