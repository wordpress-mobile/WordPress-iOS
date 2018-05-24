import WordPressFlux

/// Encapsulates saving a post for later
final class ReaderSaveForLaterAction {
    private enum Strings {
        static let postSaved = NSLocalizedString("Post saved.", comment: "Title of the notification presented in Reader when a post is saved for later")
        static let postRemoved = NSLocalizedString("Post removed.", comment: "Title of the notification presented in Reader when a post is removed from save for later")
        static let viewAll = NSLocalizedString("View All", comment: "Button in the notification presented in Reader when a post is saved for later")
        static let undo = NSLocalizedString("Undo", comment: "Button in the notification presented in Reader when a post removed from saved for later")
        static let addToSavedError = NSLocalizedString("Could not save post for later", comment: "Title of a prompt.")
        static let removeFromSavedError = NSLocalizedString("Could not remove post from Saved for Later", comment: "Title of a prompt.")
    }

    private let visibleConfirmation: Bool

    init(visibleConfirmation: Bool = false) {
        self.visibleConfirmation = visibleConfirmation
    }

    func execute(with post: ReaderPost, context: NSManagedObjectContext, completion: (() -> Void)? = nil) {
        toggleSavedForLater(post, context: context, completion: completion)
    }

    private func toggleSavedForLater(_ post: ReaderPost, context: NSManagedObjectContext, completion: (() -> Void)?) {
        let readerPostService = ReaderPostService(managedObjectContext: context)

        readerPostService.toggleSavedForLater(for: post, success: {
            self.presentSuccessNotice(for: post, context: context, completion: completion)
            completion?()
            }, failure: { error in
                self.presentErrorNotice(error, activating: !post.isSavedForLater)
                completion?()
        })
    }

    private func presentSuccessNotice(for post: ReaderPost, context: NSManagedObjectContext, completion: (() -> Void)?) {
        guard visibleConfirmation else {
            return
        }

        if post.isSavedForLater {
            presentPostSavedNotice()
        } else {
            presentPostRemovedNotice(for: post,
                                     context: context,
                                     completion: completion)
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

    private func presentPostRemovedNotice(for post: ReaderPost, context: NSManagedObjectContext, completion: (() -> Void)?) {
        guard visibleConfirmation else {
            return
        }

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
        NotificationCenter.default.post(name: .showAllSavedForLaterPosts, object: self, userInfo: nil)
    }
}
