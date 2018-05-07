import WordPressFlux

final class SaveForLaterAction {
    private enum Strings {
        static let postSaved = NSLocalizedString("Post saved.", comment: "Title of the notification presented in Reader when a post is saved for later")
        static let postRemoved = NSLocalizedString("Post removed.", comment: "Title of the notification presented in Reader when a post is removed from save for later")
        static let viewAll = NSLocalizedString("View All", comment: "Button in the notification presented in Reader when a post is saved for later")
        static let undo = NSLocalizedString("Undo", comment: "Button in the notification presented in Reader when a post removed from saved for later")
        static let addToSavedError = NSLocalizedString("Could not save post for later", comment: "Title of a prompt.")
        static let removeFromSavedError = NSLocalizedString("Could not remove post from Saved for Later", comment: "Title of a prompt.")
    }

    func execute(with post: ReaderPost, context: NSManagedObjectContext, completion: @escaping () -> Void) {
        toggleSavedForLater(post, context: context, completion: completion)
    }

    private func toggleSavedForLater(_ post: ReaderPost, context: NSManagedObjectContext, completion: @escaping () -> Void) {
        let readerPostService = ReaderPostService(managedObjectContext: context)
        readerPostService.toggleSavedForLater(for: post, success: { [weak self] in
            self?.presentSuccessNotice(for: post, context: context, completion: completion)
            completion()
            }, failure: { [weak self] error in
                self?.presentErrorNotice(error, activating: !post.isSavedForLater)
                completion()
        })
    }

    private func presentSuccessNotice(for post: ReaderPost, context: NSManagedObjectContext, completion: @escaping () -> Void) {
        if post.isSavedForLater {
            presentPostSavedNotice()
        } else {
            presentPostRemovedNotice(for: post, context: context, completion: completion)
        }
    }

    private func presentPostSavedNotice() {
        let notice = Notice(title: Strings.postSaved,
                            feedbackType: .success,
                            actionTitle: Strings.viewAll,
                            actionHandler: {
                                self.showAll()
        })

        present(notice)
    }

    private func presentPostRemovedNotice(for post: ReaderPost, context: NSManagedObjectContext, completion: @escaping () -> Void) {
        let notice = Notice(title: Strings.postRemoved,
                            feedbackType: .success,
                            actionTitle: Strings.undo,
                            actionHandler: {
                                self.toggleSavedForLater(post, context: context, completion: completion)
        })

        present(notice)
    }

    private func presentErrorNotice(_ error: Error?, activating: Bool) {
        DDLogError("Could not toggle save for later: \(String(describing: error))")

        let title = activating ? Strings.addToSavedError : Strings.removeFromSavedError

        let notice = Notice(title: title,
                            message: error?.localizedDescription,
                            feedbackType: .error)

        present(notice)
    }

    private func present(_ notice: Notice) {
        ActionDispatcher.dispatch(NoticeAction.post(notice))
    }

    private func showAll() {
        //Navigate to all saved for later
    }
}
