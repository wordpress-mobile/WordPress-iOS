import WordPressFlux


// MARK: - Mock extension. Will have to be removed when the coredata entity is updated. Marked as deprecated so it triggers a warning and we don't forget to remove it
extension ReaderPost {
    @available(*, deprecated)
    func isSavedForLater() -> Bool {
        return true
    }
}

final class SaveForLaterAction: PostAction {
    private enum Strings {
        static let postSaved = NSLocalizedString("Post saved.", comment: "Title of the notification presented in Reader when a post is saved for later")
        static let viewAll = NSLocalizedString("View All", comment: "Button in the notification presented in Reader when a post is saved for later")
        static let addToSavedError = NSLocalizedString("Could not save post for later", comment: "Title of a prompt.")
        static let removeFromSavedError = NSLocalizedString("Could not remove post from Saved for Later", comment: "Title of a prompt.")
    }

    func execute(with post: ReaderPost, context: NSManagedObjectContext ) {
        toggleSavedForLater(post, context: context)
    }

    private func toggleSavedForLater(_ post: ReaderPost, context: NSManagedObjectContext) {
        let readerPostService = ReaderPostService(managedObjectContext: context)
        readerPostService.toggleSavedForLater(for: post, success: { [weak self] in
                self?.presentSuccessNotice()
        }, failure: { [weak self] error in
            self?.presentErrorNotice(error, activating: !post.isSavedForLater())
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

    private func presentErrorNotice(_ error: Error?, activating: Bool) {
        DDLogError("Could not toggle save for later: \(String(describing: error))")

        let title = activating ? Strings.addToSavedError : Strings.removeFromSavedError

        let notice = Notice(title: title,
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
