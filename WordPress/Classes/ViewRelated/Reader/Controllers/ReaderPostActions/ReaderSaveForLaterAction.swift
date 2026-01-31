import UIKit
import WordPressData
import WordPressFlux
import WordPressUI

/// Encapsulates saving a post for later
final class ReaderSaveForLaterAction {
    private enum Strings {
        static let postSaved = NSLocalizedString("Post saved.", comment: "Title of the notification presented in Reader when a post is saved for later")
        static let postRemoved = NSLocalizedString("Post removed.", comment: "Title of the notification presented in Reader when a post is removed from save for later")
        static let addToSavedError = NSLocalizedString("Could not save post for later", comment: "Title of a prompt.")
        static let removeFromSavedError = NSLocalizedString("Could not remove post from Saved for Later", comment: "Title of a prompt.")
    }

    var visibleConfirmation: Bool

    init(visibleConfirmation: Bool = false) {
        self.visibleConfirmation = visibleConfirmation
    }

    func execute(with post: ReaderPost, context: NSManagedObjectContext = ContextManager.shared.mainContext, origin: ReaderSaveForLaterOrigin, viewController: UIViewController?, completion: (() -> Void)? = nil) {
        /// Preload the post
        if let viewController, !post.isSavedForLater {
            let offlineReaderWebView = OfflineReaderWebView()
            offlineReaderWebView.saveForLater(post, viewController: viewController)
        }

        if let viewController, !post.isSavedForLater {
            presentReaderSavedPostsAlertControllerIfNecessary(from: viewController)
        }

        trackSaveAction(for: post, origin: origin)
        toggleSavedForLater(post, context: context, origin: origin, completion: completion)
    }

    private func toggleSavedForLater(_ post: ReaderPost, context: NSManagedObjectContext, origin: ReaderSaveForLaterOrigin, completion: (() -> Void)?) {
        let readerPostService = ReaderPostService(coreDataStack: ContextManager.shared)

        readerPostService.toggleSavedForLater(for: post, success: {
            if origin == .otherStream {
                self.presentSuccessNotice(for: post, context: context, origin: origin, completion: completion)
            }
            completion?()
        }, failure: { error in
            if origin == .otherStream {
                self.presentErrorNotice(error, activating: !post.isSavedForLater)
            }
            completion?()
        })
    }

    private func presentSuccessNotice(for post: ReaderPost, context: NSManagedObjectContext, origin: ReaderSaveForLaterOrigin, completion: (() -> Void)?) {
        guard visibleConfirmation else {
            return
        }

        if post.isSavedForLater {
            present(Notice(title: Strings.postSaved, feedbackType: .success))
        } else {
            presentPostRemovedNotice(for: post,
                                     context: context,
                                     origin: origin,
                                     completion: completion)
        }
    }

    private func presentPostRemovedNotice(for post: ReaderPost, context: NSManagedObjectContext, origin: ReaderSaveForLaterOrigin, completion: (() -> Void)?) {
        guard visibleConfirmation else {
            return
        }

        let notice = Notice(title: Strings.postRemoved,
                            feedbackType: .success,
                            actionTitle: SharedStrings.Button.undo,
                            actionHandler: { _ in
                                self.trackSaveAction(for: post, origin: origin)
                                self.toggleSavedForLater(post, context: context, origin: origin, completion: completion)
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

    private func presentReaderSavedPostsAlertControllerIfNecessary(from origin: UIViewController) {
        guard !UserPersistentStoreFactory.instance().savedPostsPromoWasDisplayed else {
            return
        }
        UserPersistentStoreFactory.instance().savedPostsPromoWasDisplayed = true

        let alert = AlertView {
            AlertHeaderView(
                title: NSLocalizedString("reader.saveForLaterAlert.title", value: "Save Posts for Later", comment: "Title of alert informing users about the Reader Save for Later feature."),
                description: NSLocalizedString("reader.saveForLaterAlert.description", value: "Save this post, and come back to read it whenever you'd like. It will only be available on this device — saved posts don't sync to other devices.", comment: "Body text of alert informing users about the Reader Save for Later feature.")
            )
        } content: {
            ScaledImage("wpl-bookmark", height: 78)
                .foregroundStyle(.secondary)
        } actions: {
            AlertDismissButton()
        }
        alert.present(in: origin)
    }
}
